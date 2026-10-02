

String formatPrice(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final whole = fixed.substring(0, fixed.length - 3);
  final paisa = fixed.substring(fixed.length - 2);
  final grouped = _groupNepali(whole);
  final text = paisa == '00' ? grouped : '$grouped.$paisa';
  final sign = negative ? '-' : '';
  return '${sign}Rs. $text';
}

String _groupNepali(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  final rest = digits.substring(0, digits.length - 3);
  final groupedRest = rest.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '$groupedRest,$last3';
}