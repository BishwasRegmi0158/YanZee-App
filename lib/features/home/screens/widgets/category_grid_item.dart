import 'package:flutter/material.dart';

class CategoryGridItem extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onTap;

  const CategoryGridItem({
    super.key,
    required this.emoji,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 43,
            width: 43, 
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ), 
          ),
        ],
      ),
    );
  }
}
