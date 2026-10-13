import 'package:flutter_riverpod/legacy.dart';

/// The selected tab of SellerShell (0 Dashboard, 1 Products, 2 Orders, 3 Store).
/// The shell's nav bar and the side drawer both read and write this.
final sellerTabIndexProvider = StateProvider.autoDispose<int>((ref) => 0);