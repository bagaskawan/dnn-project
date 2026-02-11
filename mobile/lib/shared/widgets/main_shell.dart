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

  // GlobalKeys to access page states for refresh
  final _homeKey = GlobalKey<State<HomeContent>>();
  final _transactionKey = GlobalKey<State<TransactionContent>>();
  final _productKey = GlobalKey<State<ProductContent>>();
  final _contactKey = GlobalKey<State<ContactContent>>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Page Content (fills entire screen)
        IndexedStack(
          index: _currentItem.index,
          children: [
            HomeContent(
              key: _homeKey,
              onViewAllTransactionsTap: () {
                setState(() {
                  _currentItem = NavItem.transaction;
                });
                // Refresh transaction page when navigating to it
                (_transactionKey.currentState as dynamic)?.refreshData();
              },
            ),
            TransactionContent(key: _transactionKey),
            ProductContent(key: _productKey),
            ContactContent(key: _contactKey),
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
                // Refresh the newly selected page
                _refreshCurrentPage(item);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _refreshCurrentPage(NavItem item) {
    switch (item) {
      case NavItem.home:
        (_homeKey.currentState as dynamic)?.refreshData();
        break;
      case NavItem.transaction:
        (_transactionKey.currentState as dynamic)?.refreshData();
        break;
      case NavItem.product:
        (_productKey.currentState as dynamic)?.refreshData();
        break;
      case NavItem.contact:
        (_contactKey.currentState as dynamic)?.refreshData();
        break;
    }
  }
}
