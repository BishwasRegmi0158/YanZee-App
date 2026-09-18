import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/widgets/image_action_sheet.dart';
import 'package:yanzee_app/core/widgets/image_preview_screen.dart';

class AppImagePicker extends StatefulWidget {
  final Function(File pickedImage)? onImageSelected;
  final VoidCallback? onImageRemoved;

  const AppImagePicker({
    super.key,
    this.onImageSelected,
    this.onImageRemoved,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080, // Prevents memory crashes on high-res photos
        maxHeight: 1920,
        imageQuality: 80, // Optimizes compression
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _selectedImage = imageFile;
        });

        widget.onImageSelected?.call(imageFile);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
    widget.onImageRemoved?.call();
  }

  void _openThumbnailOptions() {
    if (_selectedImage == null) {
      // Nothing to preview/delete yet — go straight to gallery pick.
      _pickImage(ImageSource.gallery);
      return;
    }

    showImageActionSheet(
      context: context,
      hasImage: true,
      onPreview: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imagePath: _selectedImage!.path,
              onDelete: _removeImage,
            ),
          ),
        );
      },
      onChange: () => _pickImage(ImageSource.gallery),
      onDelete: _removeImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _openThumbnailOptions,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      cacheWidth: 800, // Downscales memory consumption during decode
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      ],
    );
  }
}