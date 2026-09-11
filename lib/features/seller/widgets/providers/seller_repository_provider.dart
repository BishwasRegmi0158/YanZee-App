import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/repositories/seller_repository.dart';

final sellerRepositoryProvider = Provider<SellerRepository>((ref) => SellerRepository());