
import 'package:flutter_riverpod/legacy.dart';

const int kHomeTabIndex = 0;
const int kShopTabIndex = 1;
const int kWishlistTabIndex = 2;
const int kCartTabIndex = 3;
const int kAccountTabIndex = 4;

final mainTabIndexProvider = StateProvider<int>((ref) => kHomeTabIndex);