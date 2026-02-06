import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

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
  final String id; // NEW: transaction ID for detail fetching
  final String name; // Store/Consumer Name
  final DateTime created_at; // Transaction time
  final double amount; // Nominal
  final TransactionType type;
  final String invoiceNumber;
  final String paymentMethod;
  final List<TransactionItem> items;

  Transaction({
    this.id = '', // Default empty for backward compatibility
    required this.name,
    required this.created_at,
    required this.amount,
    required this.type,
    required this.invoiceNumber,
    required this.paymentMethod,
    required this.items,
    this.customerPhone = "081234567890", // Default mock value
    this.customerAddress = "Jl. Merdeka No. 123", // Default mock value
  });

  final String customerPhone;
  final String customerAddress;

  /// Factory constructor from API response
  factory Transaction.fromApi(Map<String, dynamic> json) {
    // Parse created_at as DateTime
    DateTime parsedCreatedAt = DateTime.now();
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at']);
      } catch (_) {}
    }

    return Transaction(
      id: json['id'] ?? '',
      name: json['contact_name'] ?? 'Unknown',
      created_at: parsedCreatedAt,
      amount: (json['total_amount'] ?? 0).toDouble(),
      type: json['type'] == 'OUT'
          ? TransactionType.penjualan
          : TransactionType.pengadaan,
      invoiceNumber: json['invoice_number'] ?? '',
      paymentMethod: json['payment_method'] ?? 'Tunai',
      items: [], // Items loaded separately on detail page
      customerPhone: json['contact_phone'] ?? '',
      customerAddress: json['contact_address'] ?? '',
    );
  }
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

  // Transactions now loaded from API
  List<Transaction> transactions = [];
  bool isLoadingTransactions = false;
  String? transactionError;

  final ApiService _apiService = ApiService();

  /// Fetch transactions from backend API
  Future<void> fetchTransactions() async {
    isLoadingTransactions = true;
    transactionError = null;
    notifyListeners();

    try {
      final apiTransactions = await _apiService.getTransactions(limit: 20);
      transactions = apiTransactions
          .map(
            (item) => Transaction.fromApi({
              'id': item.id,
              'type': item.type,
              'transaction_date': item.transactionDate,
              'total_amount': item.totalAmount,
              'invoice_number': item.invoiceNumber,
              'payment_method': item.paymentMethod,
              'contact_name': item.contactName,
              'contact_phone': item.contactPhone,
              'contact_address': item.contactAddress,
              'created_at': item.createdAt,
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      transactionError = 'Gagal memuat transaksi';
    } finally {
      isLoadingTransactions = false;
      notifyListeners();
    }
  }

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
