
String formatNepaliStyle(double value) {
  final n = value.round().toString();
  if (n.length <= 3) return n;
  final last3 = n.substring(n.length - 3);
  final rest = n.substring(0, n.length - 3);
  final regex = RegExp(r'(\d)(?=(\d{2})+(?!\d))');
  final formattedRest = rest.replaceAllMapped(regex, (m) => '${m[1]},');
  return '$formattedRest,$last3';
}