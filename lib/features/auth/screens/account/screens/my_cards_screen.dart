import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/data/models/cards_state.dart';

/// Reads live from CardsState — nothing hardcoded. Empty until the
/// person actually adds a card here (or, later, during checkout).
class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  @override
  void initState() {
    super.initState();
    CardsState.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    CardsState.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _addCard() async {
    final last4Controller = TextEditingController();
    final holderController = TextEditingController();
    final expiryController = TextEditingController();
    String? error;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add new card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: last4Controller,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Last 4 digits'),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: holderController, decoration: const InputDecoration(labelText: 'Cardholder name')),
              TextField(controller: expiryController, decoration: const InputDecoration(labelText: 'Expiry (MM/YY)')),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final last4 = last4Controller.text.trim();
                final expiry = expiryController.text.trim();
                if (!RegExp(r'^\d{4}$').hasMatch(last4)) {
                  setDialogState(() => error = 'Enter exactly 4 digits.');
                  return;
                }
                if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(expiry)) {
                  setDialogState(() => error = 'Expiry must be in MM/YY format.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      CardsState.instance.addCard(PaymentCard(
        last4: last4Controller.text.trim(),
        holder: holderController.text.trim().isEmpty ? 'Card holder' : holderController.text.trim(),
        expiry: expiryController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = CardsState.instance.cards;

    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('My Cards', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (cards.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: const [
                    Icon(Icons.credit_card_off_outlined, size: 44, color: AuthColors.iconMuted),
                    SizedBox(height: 10),
                    Text('No cards saved yet', style: TextStyle(fontWeight: FontWeight.w700, color: AuthColors.textDark)),
                  ],
                ),
              )
            else
              for (final card in cards) _cardTile(card),
            InkWell(
              onTap: _addCard,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AuthColors.borderDefault),
                ),
                alignment: Alignment.center,
                child: const Text('+ Add new card', style: TextStyle(fontWeight: FontWeight.w600, color: AuthColors.textDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardTile(PaymentCard card) {
    return Dismissible(
      key: ValueKey(card.last4),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => CardsState.instance.removeCard(card.last4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('YANZEE · VISA', style: TextStyle(color: Color(0xFFCBB280), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 20),
            Text('•••• •••• •••• ${card.last4}', style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(card.holder, style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(card.expiry, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}