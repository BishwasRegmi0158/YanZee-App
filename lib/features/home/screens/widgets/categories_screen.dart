// categories_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/constants/categories.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            mainAxisExtent: 90,
          ),
          itemCount: categoryLabels.length,
          itemBuilder: (context, index) {
            final label = categoryLabels[index];
            final slug = categorySlugMap[label]!;
            return InkWell(
              onTap: () => context.push('/home/category/$slug', extra: label),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category_outlined),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}