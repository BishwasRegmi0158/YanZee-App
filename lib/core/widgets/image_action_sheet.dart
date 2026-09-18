import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

Future<void> showImageActionSheet({
  required BuildContext context,
  required bool hasImage,
  required VoidCallback onPreview,
  required VoidCallback onChange,
  VoidCallback? onDelete,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            ListTile(
              leading: const Icon(Iconsax.eye),
              title: const Text('Preview photo'),
              onTap: () => Navigator.pop(context, 'preview'),
            ),
          ListTile(
            leading: const Icon(Iconsax.gallery),
            title: const Text('Choose new photo'),
            onTap: () => Navigator.pop(context, 'change'),
          ),
          if (hasImage && onDelete != null)
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text(
                'Remove photo',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ListTile(
            leading: const Icon(Iconsax.close_circle),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context, null),
          ),
        ],
      ),
    ),
  );

  if (choice == 'preview') {
    onPreview();
  } else if (choice == 'change') {
    onChange();
  } else if (choice == 'delete') {
    onDelete?.call();
  }
}