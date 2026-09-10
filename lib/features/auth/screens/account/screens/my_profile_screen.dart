import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';

/// "My Profile" — shows name/email/phone read-only, with an Edit button
/// (top-right pencil) that turns the rows into editable, validated
/// fields. The avatar's camera badge is always visible/tappable —
/// independent of edit mode — so changing/removing the photo doesn't
/// require entering edit mode first.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;
  String? _emailError;
  String? _phoneError;
  String? _pendingImage; // null = unchanged, '' = removed, else new URL/path

  @override
  void initState() {
    super.initState();
    final user = AuthState.instance.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        final user = AuthState.instance.user;
        _nameController.text = user?.name ?? '';
        _emailController.text = user?.email ?? '';
        _phoneController.text = user?.phone ?? '';
        _error = null;
        _emailError = null;
        _phoneError = null;
      }
      _isEditing = !_isEditing;
    });
  }

  bool _validate() {
    String? emailErr;
    String? phoneErr;
    final nameErr = FormValidators.name(_nameController.text);
    emailErr = FormValidators.email(_emailController.text);
    phoneErr = FormValidators.phone(_phoneController.text);

    setState(() {
      _error = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
    });

    return nameErr == null && emailErr == null && phoneErr == null;
  }

  Future<void> _showPhotoOptions() async {
    final hasImage = (_currentImage() != null && _currentImage()!.isNotEmpty);
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose new photo'),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, null),
            ),
          ],
        ),
      ),
    );

    if (choice == 'pick') {
      await _pickImage();
    } else if (choice == 'remove') {
      _removeImage();
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _pendingImage = picked.path);
    await _persistImageChange();
  }

  void _removeImage() {
    setState(() => _pendingImage = '');
    _persistImageChange();
  }

  /// If the person isn't in the edit form, a photo change saves
  /// immediately (no separate "Save" step needed just for the photo).
  /// If they're mid-edit, it's folded into the normal Save Changes tap.
  Future<void> _persistImageChange() async {
    if (_isEditing) return;
    setState(() => _isSaving = true);
    try {
      await AuthService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        image: _pendingImage == '' ? null : _pendingImage,
      );
    } catch (_) {
      // Non-fatal — the picked image still shows locally even if the
      // save call fails; the person can retry from the same menu.
    }
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _pendingImage = null;
    });
  }

  String? _currentImage() {
    if (_pendingImage == null) return AuthState.instance.user?.image;
    return _pendingImage == '' ? null : _pendingImage;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() {
      _error = null;
      _isSaving = true;
    });

    try {
      await AuthService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        image: _pendingImage == ''
            ? null
            : (_pendingImage ?? AuthState.instance.user?.image),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e is AuthException ? e.message : 'Could not save changes.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
      _pendingImage = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = _currentImage();

    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_outlined,
              color: AuthColors.textDark,
            ),
            onPressed: _isSaving ? null : _toggleEdit,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFF0EEEA),
                    backgroundImage:
                        currentImage != null && currentImage.isNotEmpty
                        ? (currentImage.startsWith('http')
                              ? NetworkImage(currentImage)
                              : FileImage(File(currentImage)) as ImageProvider)
                        : null,
                    child: (currentImage == null || currentImage.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 42,
                            color: AuthColors.iconMuted,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _isSaving ? null : _showPhotoOptions,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AuthColors.errorBackground,
                  border: Border.all(color: AuthColors.errorBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠ $_error',
                  style: const TextStyle(
                    color: AuthColors.errorText,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
            _field(
              icon: Icons.person_outline,
              label: 'Name',
              controller: _nameController,
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 18),
            _field(
              icon: Icons.mail_outline,
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 18),
            _field(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            if (_isEditing) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.submitButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
                    style: AuthTextStyles.submitButton,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AuthColors.iconMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9A9A9A)),
              ),
              const SizedBox(height: 4),
              _isEditing
                  ? TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      onChanged: onChanged,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AuthColors.textDark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: const UnderlineInputBorder(),
                        errorText: errorText,
                        errorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    )
                  : Text(
                      controller.text.isEmpty ? '—' : controller.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AuthColors.textDark,
                      ),
                    ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFEDEBE7)),
            ],
          ),
        ),
      ],
    );
  }
}
