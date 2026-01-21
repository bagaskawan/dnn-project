import 'package:flutter/material.dart';

enum TransactionType {
  pengadaan, // Procurement (Green Arrow per user request)
  penjualan, // Sales (Red Arrow per user request)
}

class TransactionItem {
  final String name;
  final int quantity;
  final String unit; // e.g., "Kg", "Bal"
  final int price;
  final String? conversionNote; // e.g., "Setara dengan ≈ 60 Pcs di stok"

  TransactionItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    this.conversionNote,
  });

  int get subtotal => quantity * price;
}

class Transaction {
  final String name; // Store/Consumer Name
  final DateTime date; // Transaction time
  final double amount; // Nominal
  final TransactionType type;
  final String invoiceNumber;
  final String paymentMethod;
  final List<TransactionItem> items;

  Transaction({
    required this.name,
    required this.date,
    required this.amount,
    required this.type,
    required this.invoiceNumber,
    required this.paymentMethod,
    required this.items,
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
      invoiceNumber: "INV-20260121-001",
      paymentMethod: "Transfer Bank (Lunas)",
      items: [
        TransactionItem(
          name: "Keripik Singkong Balado",
          quantity: 3,
          unit: "Bal",
          price: 500000,
          conversionNote: "Setara dengan ≈ 60 Pcs di stok",
        ),
      ],
    ),
    Transaction(
      name: "Budi Santoso",
      date: DateTime.now().subtract(const Duration(hours: 4)),
      amount: 350000,
      type: TransactionType.penjualan,
      invoiceNumber: "INV-20260121-002",
      paymentMethod: "Tunai",
      items: [
        TransactionItem(
          name: "Alpukat Mentega Super",
          quantity: 10,
          unit: "Kg",
          price: 35000,
        ),
      ],
    ),
    Transaction(
      name: "CV. Mitra Abadi",
      date: DateTime.now().subtract(const Duration(hours: 5)),
      amount: 2100000,
      type: TransactionType.pengadaan,
      invoiceNumber: "INV-20260121-003",
      paymentMethod: "Transfer Bank",
      items: [
        TransactionItem(
          name: "Minyak Goreng Tropical",
          quantity: 5,
          unit: "Karton",
          price: 220000,
        ),
        TransactionItem(
          name: "Gula Pasir Gulaku",
          quantity: 2,
          unit: "Karung 50kg",
          price: 500000,
        ),
      ],
    ),
    // Simplified remaining transactions for brevity
    Transaction(
      name: "Siti Aminah",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      amount: 125000,
      type: TransactionType.penjualan,
      invoiceNumber: "INV-20260120-001",
      paymentMethod: "Tunai",
      items: [],
    ),
    Transaction(
      name: "UD. Sumber Rejeki",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      amount: 850000,
      type: TransactionType.pengadaan,
      invoiceNumber: "INV-20260120-002",
      paymentMethod: "Transfer Bank",
      items: [],
    ),
    Transaction(
      name: "Warung Bu Dewi",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      amount: 450000,
      type: TransactionType.penjualan,
      invoiceNumber: "INV-20260120-003",
      paymentMethod: "Tunai",
      items: [],
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
