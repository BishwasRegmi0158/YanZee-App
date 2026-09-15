import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/seller_store.dart';

class SellerStoreNotifier extends StateNotifier<SellerStore> {
  SellerStoreNotifier() : super(const SellerStore());

  void updateField({
    String? name,
    String? description,
    String? pickupAddress,
    String? contactNumber,
    String? returnPolicy,
  }) {
    state = state.copyWith(
      name: name,
      description: description,
      pickupAddress: pickupAddress,
      contactNumber: contactNumber,
      returnPolicy: returnPolicy,
    );
  }

  void updateLogo(File image) {
    state = state.copyWith(logoImage: image);
  }
}

final sellerStoreProvider = StateNotifierProvider<SellerStoreNotifier, SellerStore>((ref) {
  return SellerStoreNotifier();
});