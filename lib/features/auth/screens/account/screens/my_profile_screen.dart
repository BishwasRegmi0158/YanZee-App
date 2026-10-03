import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/navigation/full_screen_nav.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/core/widgets/image_action_sheet.dart';
import 'package:yanzee_app/core/widgets/image_preview_screen.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/data/services/user_api_service.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isSaving = false;

  /// Red banner at the top: server / general errors only.
  String? _error;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final user = AuthState.instance.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancel: put the saved values back.
        final user = AuthState.instance.user;
        _nameController.text = user?.name ?? '';
        _phoneController.text = user?.phone ?? '';
        _error = null;
        _nameError = null;
        _phoneError = null;
      }
      _isEditing = !_isEditing;
    });
  }

  bool _validate() {
    final nameErr = FormValidators.name(_nameController.text);
    final phoneErr = FormValidators.phone(_phoneController.text);

    setState(() {
      _error = null;
      _nameError = nameErr;
      _phoneError = phoneErr;
    });

    return nameErr == null && phoneErr == null;
  }

  Future<void> _showPhotoOptions() async {
    final img = AuthState.instance.user?.image;
    final hasImage = img != null && img.isNotEmpty;

    await showImageActionSheet(
      context: context,
      hasImage: hasImage,
      onPreview: () {
        if (img == null) return;
        pushFullScreen(
          context,
          ImagePreviewScreen(imagePath: img, onDelete: _removeImage),
        );
      },
      onChange: _pickImage,
      // The backend has no "delete photo" API yet, so the option is hidden.
      onDelete: null,
    );
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isSaving = true);
    String? error;
    try {
      // POST /images/user, then the logged-in user gets the new photo URL.
      await changeProfileImage(File(picked.path));
    } catch (e) {
      error = e is AuthException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  /// No backend API for this yet (only reachable from the preview screen).
  void _removeImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Removing the photo is not available yet. Choose a new photo to replace it.',
        ),
      ),
    );
  }

  ImageProvider? _getAvatarProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    if (imagePath.startsWith('http')) {
      return ResizeImage(NetworkImage(imagePath), width: 300, height: 300);
    } else {
      return ResizeImage(FileImage(File(imagePath)), width: 300, height: 300);
    }
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() {
      _error = null;
      _isSaving = true;
    });

    UserProfile updated;
    try {
      // PATCH /auth/me
      updated = await AuthService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _nameError = e.fieldErrors['fullName'];
        _phoneError = e.fieldErrors['phone'];
        final hasFieldError = _nameError != null || _phoneError != null;
        _error = hasFieldError ? null : e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not save changes.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
      // Show what the server saved (for example "+977 98.." becomes 10 digits).
      _nameController.text = updated.name;
      _phoneController.text = updated.phone ?? '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _getAvatarProvider(AuthState.instance.user?.image);

    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Iconsax.close_circle : Iconsax.edit_2,
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
                    radius: 48,
                    backgroundColor: const Color(0xFFF0EEEA),
                    backgroundImage: avatarProvider,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (avatarProvider == null
                            ? const Icon(
                                Iconsax.profile_circle,
                                size: 46,
                                color: AuthColors.iconMuted,
                              )
                            : null),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _isSaving ? null : _showPhotoOptions,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Iconsax.camera,
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
              icon: Iconsax.user,
              label: 'Name',
              controller: _nameController,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 18),
            _readOnlyField(
              icon: Iconsax.sms,
              label: 'Email',
              value: AuthState.instance.user?.email ?? '',
              note: 'Email cannot be changed.',
            ),
            const SizedBox(height: 18),
            _field(
              icon: Iconsax.call,
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

  Widget _readOnlyField({
    required IconData icon,
    required String label,
    required String value,
    String? note,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Icon(icon, size: 20, color: AuthColors.iconMuted),
        ),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _isEditing
                        ? const Color(0xFF9A9A9A)
                        : AuthColors.textDark,
                  ),
                ),
              ),
              if (_isEditing && note != null)
                Text(
                  note,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9A9A9A)),
                ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFEDEBE7)),
            ],
          ),
        ),
      ],
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
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Icon(icon, size: 20, color: AuthColors.iconMuted),
        ),
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
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        controller.text.isEmpty ? '—' : controller.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AuthColors.textDark,
                        ),
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