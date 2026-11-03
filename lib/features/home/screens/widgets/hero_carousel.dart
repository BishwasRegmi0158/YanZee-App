import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _images = [
    {'path': 'assets/images/hero_mountain.png', 'alignment': Alignment.center},
    {
      'path': 'assets/images/hero_banner1.jpg',
      'alignment': const Alignment(1, 0),
    },
    {
      'path': 'assets/images/hero_banner2.jpg',
      'alignment': const Alignment(1, 0),
    },
    {
      'path': 'assets/images/hero_banner3.png',
      'alignment': const Alignment(1, 0),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_controller.hasClients) return;

      _currentPage = (_currentPage + 1) % _images.length;
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The banner text always sits on a dark photo, so it uses the "on dark"
    // colour of the theme (white) and a scrim gradient (near black).
    final onImage = colors.onInverseSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.r2xl),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final image = _images[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      image['path'] as String,
                      fit: BoxFit.cover,
                      alignment: image['alignment'] as Alignment,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colors.scrim.withValues(alpha: 0.85),
                            colors.scrim.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.6],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'NEW ARRIVALS',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Made by Nepali,\nMade in Nepal',
                            style: context.text.headlineMedium?.copyWith(
                              color: onImage,
                              fontSize: 24,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Handcrafted heritage, modern style.',
                            style: TextStyle(
                              color: onImage.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            // dot indicator, positioned above the text block
            Positioned(
              top: 14,
              right: 16,
              child: Row(
                children: List.generate(_images.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 4),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? onImage
                          : onImage.withValues(alpha: 0.54),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}