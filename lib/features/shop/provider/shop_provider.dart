// lib/features/shop/providers/shop_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/repositories/product_repository.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';

const shopPageSize = 20;

class ShopFilters {
  /// 'all' or a backend category enum (FASHION, SPORTS, ...).
  final String category;

  /// null = all audiences, otherwise MEN / WOMEN / UNISEX / BOY / GIRL / KIDS_UNISEX.
  final String? audience;

  /// The backend has no sort parameter, so sorting is applied on the
  /// products already loaded ('price' or 'title'; anything else keeps the
  /// backend order).
  final String sortBy;
  final String order;

  final double? minPrice;
  final double? maxPrice;

  /// Kept only so the old filter sheet still compiles. The backend has no
  /// ratings, so this is ignored.
  final double? minRating;

  const ShopFilters({
    this.category = 'all',
    this.audience,
    this.sortBy = 'title',
    this.order = 'asc',
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });

  ShopFilters copyWith({
    String? category,
    String? audience,
    String? sortBy,
    String? order,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool clearAudience = false,
    bool clearPriceRange = false,
    bool clearRating = false,
  }) {
    return ShopFilters(
      category: category ?? this.category,
      audience: clearAudience ? null : (audience ?? this.audience),
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      minPrice: clearPriceRange ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPriceRange ? null : (maxPrice ?? this.maxPrice),
      minRating: clearRating ? null : (minRating ?? this.minRating),
    );
  }
}

class ShopState {
  final List<Product> products;
  final int page;
  final int totalPages;
  final int total;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final Object? error;
  final ShopFilters filters;

  const ShopState({
    this.products = const [],
    this.page = 0,
    this.totalPages = 0,
    this.total = 0,
    this.isLoadingMore = false,
    this.isInitialLoading = true,
    this.error,
    this.filters = const ShopFilters(),
  });

  bool get hasMore => page < totalPages;

  /// Price range is filtered by the backend; here we only sort.
  List<Product> get filteredProducts {
    final list = [...products];
    switch (filters.sortBy) {
      case 'price':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'title':
      case 'name':
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      default:
        return list;
    }
    return filters.order == 'desc' ? list.reversed.toList() : list;
  }

  ShopState copyWith({
    List<Product>? products,
    int? page,
    int? totalPages,
    int? total,
    bool? isLoadingMore,
    bool? isInitialLoading,
    Object? error,
    bool clearError = false,
    ShopFilters? filters,
  }) {
    return ShopState(
      products: products ?? this.products,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class ShopNotifier extends Notifier<ShopState> {
  @override
  ShopState build() {
    Future.microtask(_loadInitial);
    return const ShopState();
  }

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  Future<ProductPage> _fetch(ShopFilters f, int page) {
    return _repo.getPublicProducts(
      page: page,
      limit: shopPageSize,
      category: f.category == 'all' ? null : f.category,
      audience: f.audience,
      minPrice: f.minPrice,
      maxPrice: f.maxPrice,
    );
  }

  Future<void> _loadInitial() async {
    final requested = state.filters;
    try {
      final result = await _fetch(requested, 1);
      // Filters changed while this request was running: drop the stale answer.
      if (!identical(requested, state.filters)) return;
      state = state.copyWith(
        products: result.products,
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
        isInitialLoading: false,
      );
    } catch (e) {
      if (!identical(requested, state.filters)) return;
      state = state.copyWith(isInitialLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    final requested = state.filters;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _fetch(requested, state.page + 1);
      if (!identical(requested, state.filters)) return;
      state = state.copyWith(
        products: [...state.products, ...result.products],
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!identical(requested, state.filters)) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> updateFilters(ShopFilters filters) async {
    state = state.copyWith(
      filters: filters,
      page: 0,
      totalPages: 0,
      total: 0,
      products: [],
      isLoadingMore: false,
      isInitialLoading: true,
      clearError: true,
    );
    await _loadInitial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isInitialLoading: true, clearError: true);
    await _loadInitial();
  }
}

final shopProvider =
    NotifierProvider<ShopNotifier, ShopState>(ShopNotifier.new);