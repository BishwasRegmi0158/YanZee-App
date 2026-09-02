import 'package:flutter/material.dart';

class HeroBanner extends StatelessWidget {
  final String imageUrl;
  final String badgeText;
  final String title;
  final String subtitle;

  const HeroBanner({
    super.key,
    required this.imageUrl,
    required this.badgeText,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Image.asset(imageUrl, fit: BoxFit.cover),
          ),
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.85), // was: 0.7
                  Colors.black.withOpacity(0.0),
                ],
                stops: const [
                  0.0,
                  0.6,
                ], // was: [0.0, 0.75] — darkens more of the bottom area
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
                // Badge: px-2.5 py-0.5, text-[10px], font-bold, uppercase
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW ARRIVALS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Title: font-serif, text-2xl (24px), leading-tight, text-white
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    fontFamily: 'CormorantGaramond',
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle: text-xs (12px), text-white/80
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
