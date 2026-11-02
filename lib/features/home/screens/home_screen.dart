import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/constants/categories.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';
import 'package:yanzee_app/features/home/screens/widgets/category_grid_item.dart';
import 'package:yanzee_app/features/home/screens/widgets/category_pill.dart';
import 'package:yanzee_app/features/home/screens/widgets/hero_carousel.dart';
import 'package:yanzee_app/features/home/screens/widgets/product_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;
  final List<String> _categories = ['All', ...categoryLabels];

  final List<Map<String, String>> _categoryGrid = const [
    {'emoji': '✨', 'label': 'Just In'},
    {'emoji': '💄', 'label': 'Beauty'},
    {'emoji': '👗', 'label': 'Fashion'},
    {'emoji': '🧴', 'label': 'K-Beauty'},
    {'emoji': '🎁', 'label': 'Gifts'},
    {'emoji': '🏠', 'label': 'Home'},
    {'emoji': '🧸', 'label': 'Kids'},
    {'emoji': '🏃', 'label': 'Sports'},
  ];

  @override
  Widget build(BuildContext context) {
    final newArrivals = ref.watch(newArrivalsProvider);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ---------------- Search bar ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/search'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppTheme.rXl),
                            border: Border.all(color: colors.outline),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: colors.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Search products, brands...',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // TODO(dev-only): remove once the real "Become a Seller"
                    // entry point exists.
                    GestureDetector(
                      onTap: () => context.go('/seller-dashboard'),
                      child: Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: colors.onSurface,
                          borderRadius: BorderRadius.circular(AppTheme.rXl),
                        ),
                        child: Icon(
                          Icons.storefront_outlined,
                          color: colors.surface,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ---------------- Category pills (All / Fashion / Beauty ...) ----------------
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return CategoryPill(
                      label: _categories[index],
                      isSelected: _selectedCategory == index,
                      onTap: () {
                        setState(() => _selectedCategory = index);
                        final label = _categories[index];

                        if (label == 'All') return;

                        final slug = categorySlugMap[label];
                        if (slug != null) {
                          context.push('/home/category/$slug', extra: label);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$label category coming soon'),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ---------------- Hero carousel ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HeroCarousel(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ---------------- Categories grid ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Categories', style: context.text.headlineSmall),
                    GestureDetector(
                      onTap: () => context.push('/home/categories'),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 70,
                  ),
                  itemCount: _categoryGrid.length,
                  itemBuilder: (context, index) => CategoryGridItem(
                    emoji: _categoryGrid[index]['emoji']!,
                    label: _categoryGrid[index]['label']!,
                    onTap: () {
                      final label = _categoryGrid[index]['label']!;
                      final slug = categorySlugMap[label];
                      if (slug != null) {
                        context.push('/home/category/$slug', extra: label);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$label category coming soon'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ---------------- New Arrivals (real API data) ----------------
            SliverToBoxAdapter(
              child: ProductSection(
                title: 'New Arrivals',
                subtitle: 'The latest additions',
                value: newArrivals,
                provider: newArrivalsProvider,
                onSeeAll: () => context.push('/home/new-arrivals'),
              ),
            ),

            // ---------------- Bottom safe spacing ----------------
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}