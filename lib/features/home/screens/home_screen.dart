import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_text_styles.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';
import 'package:yanzee_app/features/home/screens/widgets/category_grid_item.dart';
import 'package:yanzee_app/features/home/screens/widgets/category_pill.dart';
import 'package:yanzee_app/features/home/screens/widgets/hero_banner.dart';
import 'package:yanzee_app/features/home/screens/widgets/product_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;
  final List<String> _categories = [
    'All',
    'Fashion',
    'Beauty',
    'Sports',
    'Kids',
  ];

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

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Search products, brands...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 20,
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
                      onTap: () => setState(() => _selectedCategory = index),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ---------------- Hero banner ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HeroBanner(
                  imageUrl: 'assets/images/hero_mountain.png',
                  badgeText: 'NEW ARRIVALS',
                  title: 'Made by Nepali,\nMade in Nepal',
                  subtitle: 'Handcrafted heritage, modern style.',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ---------------- Categories grid (Just In / Beauty / Fashion ...) ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          color: Color(0xFFE53935),
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
                    onTap: () {},
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
                onSeeAll: () {},
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
