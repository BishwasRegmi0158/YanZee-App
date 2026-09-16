import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_dashboard_visit_provider.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_dashboard_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_orders_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_products_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_store_screen.dart';

class SellerShell extends ConsumerStatefulWidget {
  const SellerShell({super.key});

  @override
  ConsumerState<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends ConsumerState<SellerShell> {
  late final PersistentTabController _controller = PersistentTabController(
    initialIndex: 0,
  );

  // Phosphor's regular/fill weights share the same grid, so no per-icon
  // offset correction is needed here (unlike the old iconsax bold set).
  final List<_PillNavItem> _items = const [
    _PillNavItem(
      activeIcon: PhosphorIconsFill.squaresFour,
      inactiveIcon: PhosphorIconsRegular.squaresFour,
      label: 'Dashboard',
    ),
    _PillNavItem(
      activeIcon: PhosphorIconsFill.package,
      inactiveIcon: PhosphorIconsRegular.package,
      label: 'Products',
    ),
    _PillNavItem(
      activeIcon: PhosphorIconsFill.receipt,
      inactiveIcon: PhosphorIconsRegular.receipt,
      label: 'Orders',
    ),
    _PillNavItem(
      activeIcon: PhosphorIconsFill.storefront,
      inactiveIcon: PhosphorIconsRegular.storefront,
      label: 'Store',
    ),
  ];

  List<CustomNavBarScreen> _buildScreens() {
    return const [
      CustomNavBarScreen(screen: SellerDashboardScreen()),
      CustomNavBarScreen(screen: SellerProductsScreen()),
      CustomNavBarScreen(screen: SellerOrdersScreen()),
      CustomNavBarScreen(screen: SellerStoreScreen()),
    ];
  }

  void _onItemSelected(int index) {
    // Every Dashboard selection gets a fresh chart key so the line animation
    // plays both when returning to Dashboard and when tapping it again.
    if (index == 0) {
      ref.read(sellerDashboardVisitProvider.notifier).state++;
    }
    setState(() {
      _controller.index = index; // required by the package
    });
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
        onItemSelected: _onItemSelected,
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
  const _PillNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
}

/// Custom nav bar widget passed to PersistentTabView.custom. Inactive
/// tabs render as plain outline icons; the active tab expands into a
/// colored pill with a filled icon stacked above the label.
class _PillNavBar extends StatelessWidget {
  const _PillNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<_PillNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  // Active pill color.
  static const Color _activeColor = Colors.black;

  // Fixed footprint for every pill/icon slot so "Dashboard" and "Store"
  // render at identical size regardless of label length.
  static const double _pillWidth = 76;
  static const double _pillHeight = 44;
  static const double _iconSlotSize = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    width: isSelected ? _pillWidth : _iconSlotSize,
                    height: isSelected ? _pillHeight : _iconSlotSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? _activeColor : Colors.transparent,
                      // Perfect stadium/pill shape.
                      borderRadius: BorderRadius.circular(_pillHeight / 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          isSelected ? item.activeIcon : item.inactiveIcon,
                          size: 20,
                          color: isSelected ? Colors.white : inactiveColor,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
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