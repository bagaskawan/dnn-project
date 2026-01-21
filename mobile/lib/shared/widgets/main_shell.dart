import 'package:flutter/material.dart';
import '../../features/contact/contact_page.dart';
import '../../features/home/home_page.dart';
import '../../features/product/product_page.dart';
import '../../features/transaction/transaction_page.dart';
import 'app_bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  NavItem _currentItem = NavItem.home;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Page Content (fills entire screen)
        IndexedStack(
          index: _currentItem.index,
          children: [
            HomeContent(
              onViewAllTransactionsTap: () {
                setState(() {
                  _currentItem = NavItem.transaction;
                });
              },
            ),
            TransactionContent(),
            ProductContent(),
            ContactContent(),
          ],
        ),
        // Fixed Bottom Nav (floating on top)
        Positioned(
          left: 0,
          right: 0,
          bottom: AppBottomNavBar.bottomPosition,
          child: Center(
            child: AppBottomNavBar(
              currentItem: _currentItem,
              onItemSelected: (item) {
                setState(() {
                  _currentItem = item;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
