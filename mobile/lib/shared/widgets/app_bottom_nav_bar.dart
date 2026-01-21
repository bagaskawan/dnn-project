import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

enum NavItem { home, transaction, product, contact }

class AppBottomNavBar extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onItemSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentItem,
    required this.onItemSelected,
  });

  /// Standard bottom position for consistent placement across all pages
  static const double bottomPosition = 24;

  static const double _itemSize = 50.0;
  static const double _itemSpacing = 5.0;

  @override
  Widget build(BuildContext context) {
    final totalWidth =
        (4 * _itemSize) +
        (3 * _itemSpacing) +
        16; // 4 items + 3 spacings + padding

    return Container(
      width: totalWidth,
      height: _itemSize + 16, // item height + padding
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: currentItem.index * (_itemSize + _itemSpacing),
            top: 0,
            bottom: 0,
            child: Container(
              width: _itemSize,
              height: _itemSize,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Nav items
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavItem(Icons.home_rounded, NavItem.home),
              const SizedBox(width: _itemSpacing),
              _buildNavItem(Icons.receipt_long_rounded, NavItem.transaction),
              const SizedBox(width: _itemSpacing),
              _buildNavItem(Icons.inventory_2_rounded, NavItem.product),
              const SizedBox(width: _itemSpacing),
              _buildNavItem(Icons.contacts_rounded, NavItem.contact),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, NavItem item) {
    final isSelected = currentItem == item;
    return GestureDetector(
      onTap: () => onItemSelected(item),
      child: SizedBox(
        width: _itemSize,
        height: _itemSize,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(color: isSelected ? Colors.black : Colors.white54),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white54,
              size: isSelected ? 26 : 24,
            ),
          ),
        ),
      ),
    );
  }
}
