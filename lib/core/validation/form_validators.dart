class FormValidators {
  static final _nameRegex = RegExp(r"^[a-zA-Z][a-zA-Z\s.'-]*$");
  static final _emailRegex = RegExp(r'^\S+@\S+\.\S+$');


  static final _nepaliMobileRegex = RegExp(r'^9(6|7|8)\d{8}$');

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
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Phone number is required.';

    var digits = raw.replaceAll(RegExp(r'[\s-]'), '');

   
    if (digits.startsWith('+977')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('977') && digits.length > 10) {
      digits = digits.substring(3);
    }

    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Phone number must contain digits only.';
    }
    if (digits.length != 10) {
      return 'Enter a 10-digit mobile number.';
    }
    if (!_nepaliMobileRegex.hasMatch(digits)) {
      return 'Enter a valid Ncell, NTC (Namaste) or Smart Cell number.';
    }
    return null;
  }

  
  static String? carrierFor(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (digits.length != 10) return null;
    final prefix = digits.substring(0, 3);
    const ncell = {'980', '981', '982', '986'};
    const ntc = {'974', '975', '976', '984', '985'};
    const smartCell = {'961', '962', '988'};
    if (ncell.contains(prefix)) return 'Ncell';
    if (ntc.contains(prefix)) return 'NTC (Namaste)';
    if (smartCell.contains(prefix)) return 'Smart Cell';
    return null;
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