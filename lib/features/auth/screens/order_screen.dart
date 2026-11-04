import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    'To Pay',
    'To Ship',
    'To Receive',
    'To Review',
    'Returns',
  ];

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
    // Inter is applied to this screen only. The app-wide theme is untouched.
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
      ),
      child: Scaffold(
        backgroundColor: AuthColors.pageBackground,
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: Colors.white,
          foregroundColor: AuthColors.textDark,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AuthColors.textDark,
            unselectedLabelColor: const Color(0xFF9E9E9E),
            indicatorColor: AuthColors.textDark,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          // TODO: swap each placeholder for a real order-list widget fed by
          // your API, filtered by that order status.
          children: _tabs.map((t) => _EmptyOrdersState(label: t)).toList(),
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // Scrolls on very short screens (landscape) so it can never overflow.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Iconsax.box,
                    size: 48,
                    color: Color(0xFFCFCDC9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing in "$label" yet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B6B6B)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}