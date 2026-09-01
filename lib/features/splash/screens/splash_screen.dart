import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase boundaries on the 0.0-1.0 timeline.
  static const double _nepaliEnd = 0.4;
  static const double _englishStart = 0.4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();
    _navigateNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 1000));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Home'))),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 2),
          decoration: const BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  
  Widget _nepaliWord(String word) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = (_controller.value / _nepaliEnd).clamp(0.0, 1.0);
        final double eased = Curves.easeOut.transform(t);
        final double spacing = lerpDouble(18, 0, eased)!;
        final double opacity = lerpDouble(0.2, 1.0, eased)!;

        return Opacity(
          opacity: opacity,
          child: Text(
            word,
            style: TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: spacing,
              color: AppColors.textGray,
            ),
          ),
        );
      },
    );
  }

 Widget _animatedLetter(String letter, int index, int total) {
  final double phaseLength = 1.0 - _englishStart;
  final double start = _englishStart + (index / total) * phaseLength;
  final double end = _englishStart + ((index + 1) / total) * phaseLength;

  return AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final double t = _controller.value;
      double progress = 0;

      if (t >= start && t <= end) {
        final double local = (t - start) / (end - start);
        progress = local < 0.5 ? local * 2 : (1 - local) * 2;
      } else if (t > end) {
        progress = 0;
      }

      final double scale = 1.0 + (progress * 0.3);
      final FontWeight weight =
          progress > 0.3 ? FontWeight.w900 : FontWeight.bold;

      return Transform.scale(
        scale: scale,
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: weight,
            fontSize: 32,
            color: Color.lerp(AppColors.textGray, Colors.white, progress),
            shadows: progress > 0
                ? [
                    Shadow(
                      color: AppColors.accentRed.withOpacity(progress),
                      blurRadius: 8 * progress,
                    ),
                    Shadow(
                      color: AppColors.accentRed.withOpacity(progress * 0.6),
                      blurRadius: 24 * progress,
                    ),
                  ]
                : [],
          ),
        ),
      );
    },
  );
}
  Widget _animatedWord(String word) {
    final letters = word.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < letters.length; i++)
          _animatedLetter(letters[i], i, letters.length),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: _dots(),
            ),
            const SizedBox(height: 2),
            _nepaliWord('यांजी'),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: _dots(),
            ),
            const SizedBox(height: 2),
            _animatedWord('YänZee'),
            const SizedBox(height: 18),
            const Text(
              'loading',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 13,
                letterSpacing: 6,
                color: AppColors.loadingGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}