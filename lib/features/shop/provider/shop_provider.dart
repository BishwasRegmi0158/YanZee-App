import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/repositories/product_repository.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';

const shopPageSize = 20;

class ShopFilters {
  final String category;
  final String sortBy;
  final String order;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;

  const ShopFilters({
    this.category = 'all',
    this.sortBy = 'title',
    this.order = 'asc',
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });

  ShopFilters copyWith({
    String? category,
    String? sortBy,
    String? order,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool clearPriceRange = false,
    bool clearRating = false,
  }) {
    return ShopFilters(
      category: category ?? this.category,
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
  final int skip;
  final int total;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final Object? error;
  final ShopFilters filters;

  const ShopState({
    this.products = const [],
    this.skip = 0,
    this.total = 0,
    this.isLoadingMore = false,
    this.isInitialLoading = true,
    this.error,
    this.filters = const ShopFilters(),
  });

  bool get hasMore => products.length < total;

  List<Product> get filteredProducts {
    return products.where((p) {
      if (filters.minPrice != null && p.price < filters.minPrice!) {
        return false;
      }
      if (filters.maxPrice != null && p.price > filters.maxPrice!) {
        return false;
      }
      if (filters.minRating != null && p.rating < filters.minRating!) {
        return false;
      }
      return true;
    }).toList();
  }

  ShopState copyWith({
    List<Product>? products,
    int? skip,
    int? total,
    bool? isLoadingMore,
    bool? isInitialLoading,
    Object? error,
    bool clearError = false,
    ShopFilters? filters,
  }) {
    return ShopState(
      products: products ?? this.products,
      skip: skip ?? this.skip,
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
    // _loadInitial() reads `state.filters` and would throw if run
    // synchronously here, before this method returns. Future.microtask
    // defers it to run right after build() completes and the provider
    // is fully mounted, so reading/writing `state` inside it is safe.
    Future.microtask(_loadInitial);
    return const ShopState();
  }

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  Future<void> _loadInitial() async {
    try {
      final page = await _repo.getProducts(
        limit: shopPageSize,
        skip: 0,
        category: state.filters.category,
        sortBy: state.filters.sortBy,
        order: state.filters.order,
      );
      state = state.copyWith(
        products: page.products,
        skip: page.skip + page.products.length,
        total: page.total,
        isInitialLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isInitialLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.getProducts(
        limit: shopPageSize,
        skip: state.skip,
        category: state.filters.category,
        sortBy: state.filters.sortBy,
        order: state.filters.order,
      );
      state = state.copyWith(
        products: [...state.products, ...page.products],
        skip: page.skip + page.products.length,
        total: page.total,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> updateFilters(ShopFilters filters) async {
    state = state.copyWith(
      filters: filters,
      skip: 0,
      products: [],
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

final shopProvider = NotifierProvider<ShopNotifier, ShopState>(ShopNotifier.new);