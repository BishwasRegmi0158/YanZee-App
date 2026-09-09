// Place at: lib/features/account/screens/orders_screen.dart

import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  static const _tabs = ['To Pay', 'To Ship', 'To Receive', 'To Review', 'Returns'];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        foregroundColor: AuthColors.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AuthColors.textDark,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: AuthColors.textDark,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // TODO: swap each placeholder for a real order-list widget fed by your API,
        // filtered by that order status.
        children: _tabs.map((t) => _EmptyOrdersState(label: t)).toList(),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFCFCDC9)),
          const SizedBox(height: 12),
          Text('No orders $label', style: const TextStyle(color: Color(0xFF6B6B6B))),
        ],
      ),
    );
  }
}