import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/features/home/screens/widgets/product_card.dart';
import 'package:yanzee_app/features/shop/provider/shop_provider.dart';
import 'package:yanzee_app/features/shop/widgets/filter_sheet.dart';
import 'package:yanzee_app/features/shop/widgets/shop_filter_bar.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(shopProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          ShopFilterBar(
            filters: state.filters,
            onChanged: (f) => ref.read(shopProvider.notifier).updateFilters(f),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ShopState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.filteredProducts.isEmpty) {
      return _ErrorView(
        onRetry: () => ref.read(shopProvider.notifier).refresh(),
      );
    }
    if (state.filteredProducts.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(shopProvider.notifier).refresh(),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 260,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.filteredProducts.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.filteredProducts.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return ProductCard(product: state.filteredProducts[index]);
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Something went wrong.'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
