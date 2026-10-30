import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/services/seller_product_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_repository_provider.dart';

final sellerProductApiProvider = Provider((ref) => SellerProductApiService());

/// The category picked in the products filter (null = all categories).
final productCategoryFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// One image in the product form: an already-uploaded URL, or a new file
/// that still has to be uploaded when the product is saved.
class ProductImageEntry {
  final String? url;
  final File? file;
  const ProductImageEntry.remote(String this.url) : file = null;
  const ProductImageEntry.local(File this.file) : url = null;
}

/// The images of each variant, by the variant's position in the list.
typedef VariantImages = Map<int, List<ProductImageEntry>>;

typedef SaveResult = ({bool saved, String? message});

class SellerProductsNotifier extends AsyncNotifier<List<SellerProduct>> {
  @override
  Future<List<SellerProduct>> build() async {
    // Reloads when the filter changes or when the selected shop changes.
    final categoryId = ref.watch(productCategoryFilterProvider);
    await ref.watch(myShopProvider.future);
    return ref
        .watch(sellerRepositoryProvider)
        .getProducts(categoryId: categoryId);
  }

  SellerProductApiService get _api => ref.read(sellerProductApiProvider);

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _reload() async {
    try {
      final fresh = await ref
          .read(sellerRepositoryProvider)
          .getProducts(categoryId: ref.read(productCategoryFilterProvider));
      state = AsyncData(fresh);
    } catch (_) {
      // The save itself worked; keep showing the old list.
    }
  }

  /// Uploads new files and returns the final ordered list of URLs.
  Future<List<String>> _resolveImages(List<ProductImageEntry> entries) async {
    final urls = <String>[];
    for (final e in entries) {
      if (e.file != null) {
        urls.add(await _api.uploadProductImage(e.file!));
      } else if (e.url != null) {
        urls.add(e.url!);
      }
    }
    return urls;
  }

  /// Uploads the new image files of every variant and puts the final URLs
  /// into the variants.
  Future<List<SellerVariant>> _resolveVariantImages(
    List<SellerVariant> variants,
    VariantImages images,
  ) async {
    final result = <SellerVariant>[];
    for (var i = 0; i < variants.length; i++) {
      final entries = images[i];
      if (entries == null) {
        result.add(variants[i]);
      } else {
        result.add(variants[i].copyWith(imageUrls: await _resolveImages(entries)));
      }
    }
    return result;
  }

  bool _same(Map<String, dynamic> a, Map<String, dynamic> b) =>
      jsonEncode(a) == jsonEncode(b);

  /// Uploads the images, POST /products, then PATCH /seo when SEO details
  /// were filled in.
  Future<SaveResult> addProduct(
    SellerProduct draft, {
    List<ProductImageEntry> images = const [],
    VariantImages variantImages = const {},
    File? seoImage,
  }) async {
    var id = '';
    String? seoUrl = draft.seoImage;
    try {
      final urls = await _resolveImages(images);
      final variants = await _resolveVariantImages(draft.variants, variantImages);
      if (seoImage != null) seoUrl = await _api.uploadSeoImage(seoImage);
      id = await _api.createProduct(
        draft.copyWith(variants: variants).toCreateJson(imageUrls: urls),
      );
    } catch (e) {
      return (saved: false, message: _msg(e));
    }

    String? warning;
    final seo = draft.seoJson(image: seoUrl);
    if (seo.isNotEmpty) {
      try {
        await _api.updateSeo(id, seo);
      } catch (e) {
        warning =
            'Product created, but the SEO details could not be saved: ${_msg(e)}';
      }
    }
    await _reload();
    return (saved: true, message: warning);
  }

  /// Saves only the sections that changed, each with its own endpoint.
  Future<SaveResult> updateProduct(
    SellerProduct original,
    SellerProduct edited, {
    List<ProductImageEntry> images = const [],
    VariantImages variantImages = const {},
    File? seoImage,
  }) async {
    final id = original.id;
    var urls = <String>[];
    var variants = edited.variants;
    String? seoUrl = edited.seoImage;

    try {
      urls = await _resolveImages(images);
      variants = await _resolveVariantImages(edited.variants, variantImages);
      if (seoImage != null) seoUrl = await _api.uploadSeoImage(seoImage);
    } catch (e) {
      return (saved: false, message: _msg(e));
    }

    final ready = edited.copyWith(variants: variants);
    final steps = <(String, Future<void> Function())>[];

    final general = ready.generalJson(imageUrls: urls);
    if (!_same(general, original.generalJson())) {
      steps.add(('Details', () => _api.updateGeneral(id, general)));
    }

    // Prices, variants and variant images. No quantity: stock changes only
    // through Stock in. The complete variant list is sent: a new variant has
    // no id (the server creates it) and a saved variant that is missing from
    // the list is deleted by the server.
    final inventory = ready.inventoryUpdateJson();
    if (!_same(inventory, original.inventoryUpdateJson())) {
      steps.add(
        ('Pricing and variants', () => _api.updateInventory(id, inventory)),
      );
    }

    if (ready.status != original.status) {
      steps.add(('Status', () => _api.updateStatus(id, ready.status)));
    }

    final custom = ready.customJson();
    if (!_same(custom, original.customJson())) {
      steps.add(('Tags and release date', () => _api.updateCustom(id, custom)));
    }

    final seo = ready.seoJson(image: seoUrl);
    if (seo.isNotEmpty && !_same(seo, original.seoJson())) {
      steps.add(('SEO', () => _api.updateSeo(id, seo)));
    }

    for (final (label, run) in steps) {
      try {
        await run();
      } catch (e) {
        await _reload();
        return (saved: false, message: '$label could not be saved: ${_msg(e)}');
      }
    }

    await _reload();
    return (
      saved: true,
      message: steps.isEmpty ? 'No changes to save' : null,
    );
  }

  /// PATCH /products/:id/status. Changes the list at once and puts it back
  /// if the server refuses. Returns null on success, or an error message.
  Future<String?> setStatus(String id, ProductStatus status) async {
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData([
        for (final p in previous) p.id == id ? p.copyWith(status: status) : p,
      ]);
    }
    try {
      await _api.updateStatus(id, status);
      return null;
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return _msg(e);
    }
  }

  /// DELETE /products/:id. Removes it at once and puts it back if refused.
  Future<String?> deleteProduct(String id) async {
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData(previous.where((p) => p.id != id).toList());
    }
    try {
      await _api.deleteProduct(id);
      return null;
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return _msg(e);
    }
  }
}

// autoDispose, so leaving the seller area (e.g. logout) clears the data.
// retry: null, so a failed request shows an error instead of loading forever.
final sellerProductsProvider = AsyncNotifierProvider.autoDispose<
    SellerProductsNotifier, List<SellerProduct>>(
  SellerProductsNotifier.new,
  retry: (retryCount, error) => null,
);