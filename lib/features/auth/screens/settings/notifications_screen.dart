import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

/// Local toggle only — wire `_pushEnabled` up to your real notifications
/// backend/FCM topic subscription once that exists.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _orderUpdates = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('Notifications', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Pause all notifications'),
              subtitle: const Text('Temporarily stop receiving any notifications'),
              value: !_pushEnabled,
              onChanged: (paused) => setState(() => _pushEnabled = !paused),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Order updates'),
              value: _orderUpdates && _pushEnabled,
              onChanged: _pushEnabled ? (v) => setState(() => _orderUpdates = v) : null,
            ),
            SwitchListTile(
              title: const Text('Promotions & offers'),
              value: _promotions && _pushEnabled,
              onChanged: _pushEnabled ? (v) => setState(() => _promotions = v) : null,
            ),
          ],
        ),
      ),
    );
  }
}