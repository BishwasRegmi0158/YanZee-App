import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_dashboard_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_orders_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_products_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_store_screen.dart';

class SellerShell extends StatefulWidget {
  const SellerShell({super.key});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  late final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  final List<_PillNavItem> _items = const [
    _PillNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _PillNavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
    _PillNavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
    _PillNavItem(icon: Icons.storefront_outlined, label: 'Store'),
  ];

  List<CustomNavBarScreen> _buildScreens() {
    return const [
      CustomNavBarScreen(screen: SellerDashboardScreen()),
      CustomNavBarScreen(screen: SellerProductsScreen()),
      CustomNavBarScreen(screen: SellerOrdersScreen()),
      CustomNavBarScreen(screen: SellerStoreScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView.custom(
      context,
      controller: _controller,
      itemCount: _items.length,
      screens: _buildScreens(),
      customWidget: _PillNavBar(
        items: _items,
        selectedIndex: _controller.index,
        onItemSelected: (index) {
          setState(() {
            _controller.index = index; // required by the package
          });
        },
      ),
      navBarHeight: 64,
      backgroundColor: Theme.of(context).colorScheme.surface,
      confineToSafeArea: true,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
    );
  }
}

class _PillNavItem {
  const _PillNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Custom nav bar widget passed to PersistentTabView.custom, styled after
/// persistent_bottom_nav_bar's "Style7": inactive tabs render as plain
/// icons, the active tab expands into a colored pill with icon + label.
class _PillNavBar extends StatelessWidget {
  const _PillNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<_PillNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeColor = Colors.black;
    final inactiveColor = Colors.grey.shade500;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == selectedIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onItemSelected(index),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                    // Slightly tighter horizontal padding than before --
                    // frees up room for longer labels like "Dashboard"
                    // to fit without truncating as aggressively.
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 12 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    // Row no longer uses mainAxisSize.min -- that let the
                    // content demand more width than its Expanded slot
                    // could give it, which is what caused the "RIGHT
                    // OVERFLOWED BY 28 PIXELS" error on the "Dashboard"
                    // pill. The label is now Flexible with ellipsis so it
                    // shrinks to fit instead of overflowing.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected ? Colors.white : inactiveColor,
                        ),
                        if (isSelected)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}