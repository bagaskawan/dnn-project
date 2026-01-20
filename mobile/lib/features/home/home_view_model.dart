import 'package:flutter/material.dart';

enum TransactionType {
  pengadaan, // Procurement (Green Arrow per user request)
  penjualan, // Sales (Red Arrow per user request)
}

class Transaction {
  final String name; // Store/Consumer Name
  final DateTime date; // Transaction time
  final double amount; // Nominal
  final TransactionType type;

  Transaction({
    required this.name,
    required this.date,
    required this.amount,
    required this.type,
  });
}

class QuickTransferContact {
  final String name;
  final String avatarUrl;

  QuickTransferContact({required this.name, required this.avatarUrl});
}

class PortfolioItem {
  final String name;
  final String ticker;
  final double price;
  final double change;
  final double changePercent;
  final String logoUrl;
  final Color backgroundColor;

  PortfolioItem({
    required this.name,
    required this.ticker,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.logoUrl,
    required this.backgroundColor,
  });
}

class WatchlistItem {
  final String name;
  final String ticker;
  final double price;
  final double changePercent;
  final String logoUrl;

  WatchlistItem({
    required this.name,
    required this.ticker,
    required this.price,
    required this.changePercent,
    required this.logoUrl,
  });
}

class HomeViewModel extends ChangeNotifier {
  String userName = "Jack Sparrow";
  String greeting = "Hello, Jack Sparrow!";
  double balance = 112340.00;
  double monthlyChange = 10240.00;
  double monthlyChangePercent = 12;
  double income = 20450;
  double expense = 22450;
  double incomeChange = 12.06;
  double expenseChange = 12.06;
  bool isBalanceVisible = true;

  List<PortfolioItem> portfolioItems = [
    PortfolioItem(
      name: 'Sbux',
      ticker: 'Sbux',
      price: 80.30,
      change: 1.80,
      changePercent: 1.32,
      logoUrl: 'https://logo.clearbit.com/starbucks.com',
      backgroundColor: const Color(0xFFE8F5E9),
    ),
    PortfolioItem(
      name: 'Nike',
      ticker: 'Nike, Inc.',
      price: 111.05,
      change: -2.85,
      changePercent: -0.32,
      logoUrl: 'https://logo.clearbit.com/nike.com',
      backgroundColor: const Color(0xFFA39EFF),
    ),
  ];

  List<WatchlistItem> watchlistItems = [
    WatchlistItem(
      name: 'Sbux',
      ticker: 'Starbucks',
      price: 35.123,
      changePercent: 14,
      logoUrl: 'https://logo.clearbit.com/starbucks.com',
    ),
  ];

  List<QuickTransferContact> quickTransferContacts = [
    QuickTransferContact(
      name: "Jone",
      avatarUrl: "https://i.pravatar.cc/150?img=1",
    ),
    QuickTransferContact(
      name: "Mojo",
      avatarUrl: "https://i.pravatar.cc/150?img=2",
    ),
    QuickTransferContact(
      name: "Emie",
      avatarUrl: "https://i.pravatar.cc/150?img=3",
    ),
    QuickTransferContact(
      name: "Smith",
      avatarUrl: "https://i.pravatar.cc/150?img=4",
    ),
    QuickTransferContact(
      name: "Emy",
      avatarUrl: "https://i.pravatar.cc/150?img=5",
    ),
  ];

  List<Transaction> transactions = [
    Transaction(
      name: "Toko Berkah Jaya",
      date: DateTime.now().subtract(const Duration(hours: 2)),
      amount: 1500000,
      type: TransactionType.pengadaan,
    ),
    Transaction(
      name: "Budi Santoso",
      date: DateTime.now().subtract(const Duration(hours: 4)),
      amount: 350000,
      type: TransactionType.penjualan,
    ),
    Transaction(
      name: "CV. Mitra Abadi",
      date: DateTime.now().subtract(const Duration(hours: 5)),
      amount: 2100000,
      type: TransactionType.pengadaan,
    ),
    Transaction(
      name: "Siti Aminah",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      amount: 125000,
      type: TransactionType.penjualan,
    ),
    Transaction(
      name: "UD. Sumber Rejeki",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      amount: 850000,
      type: TransactionType.pengadaan,
    ),
    Transaction(
      name: "Warung Bu Dewi",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      amount: 450000,
      type: TransactionType.penjualan,
    ),
    Transaction(
      name: "Ahmad Rizky",
      date: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      amount: 75000,
      type: TransactionType.penjualan,
    ),
    Transaction(
      name: "PT. Global Textil",
      date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      amount: 3200000,
      type: TransactionType.pengadaan,
    ),
    Transaction(
      name: "Lina Marlina",
      date: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
      amount: 200000,
      type: TransactionType.penjualan,
    ),
    Transaction(
      name: "Toko Serba Ada",
      date: DateTime.now().subtract(const Duration(days: 3, hours: 8)),
      amount: 550000,
      type: TransactionType.pengadaan,
    ),
    Transaction(
      name: "Doni Pratama",
      date: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
      amount: 180000,
      type: TransactionType.penjualan,
    ),
    Transaction(
      name: "Supplier Kain Murah",
      date: DateTime.now().subtract(const Duration(days: 4, hours: 5)),
      amount: 950000,
      type: TransactionType.pengadaan,
    ),
    Transaction(
      name: "Cafe Kopi Senja",
      date: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
      amount: 600000,
      type: TransactionType.penjualan,
    ),
    Transaction(
      name: "Toko Kelontong Maju",
      date: DateTime.now().subtract(const Duration(days: 5, hours: 6)),
      amount: 1200000,
      type: TransactionType.pengadaan,
    ),
    Transaction(
      name: "Rina Wati",
      date: DateTime.now().subtract(const Duration(days: 6, hours: 3)),
      amount: 95000,
      type: TransactionType.penjualan,
    ),
  ];

  void toggleBalanceVisibility() {
    isBalanceVisible = !isBalanceVisible;
    notifyListeners();
  }

  int selectedNavIndex = 0;

  void setNavIndex(int index) {
    selectedNavIndex = index;
    notifyListeners();
  }
}
