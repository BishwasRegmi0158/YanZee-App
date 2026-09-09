import 'package:flutter/foundation.dart';

/// Card data starts empty and only grows when the person actually adds
/// a card from My Cards (or, later, from checkout). Never store full
/// card numbers or CVVs here in a real build — only a tokenized
/// reference from your payment provider plus the last 4 digits.
class PaymentCard {
  const PaymentCard({required this.last4, required this.holder, required this.expiry});

  final String last4;
  final String holder;
  final String expiry;
}

class CardsState extends ChangeNotifier {
  CardsState._();
  static final CardsState instance = CardsState._();

  final List<PaymentCard> _cards = [];

  List<PaymentCard> get cards => List.unmodifiable(_cards);

  void addCard(PaymentCard card) {
    _cards.add(card);
    notifyListeners();
  }

  void removeCard(String last4) {
    _cards.removeWhere((c) => c.last4 == last4);
    notifyListeners();
  }

  void clear() {
    _cards.clear();
    notifyListeners();
  }
}