class FormValidators {
  static final _nameRegex = RegExp(r"^[a-zA-Z][a-zA-Z\s.'-]*$");
  static final _emailRegex = RegExp(r'^\S+@\S+\.\S+$');
  static final _phoneRegex = RegExp(r'^\+?\d{7,15}$');

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name is required.';
    if (name.length < 2 || !_nameRegex.hasMatch(name)) {
      return 'Enter a valid name.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    return _emailRegex.hasMatch(email) ? null : 'Enter a valid email address.';
  }

  static String? phone(String? value) {
    final rawPhone = value?.trim() ?? '';
    final digitsOnly = rawPhone.replaceAll(RegExp(r'[\s-]'), '');
    if (rawPhone.isEmpty) return 'Phone number is required.';
    return _phoneRegex.hasMatch(digitsOnly)
        ? null
        : 'Enter a valid phone number (7–15 digits).';
  }

  static String? required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  static String? password(String? value) {
    return value == null || value.isEmpty ? 'Password is required.' : null;
  }

  static String? confirmPassword(String? value) {
    return value == null || value.isEmpty
        ? 'Please confirm your password.'
        : null;
  }
}
