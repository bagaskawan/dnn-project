import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';
import 'add-contact/add_contact_modal.dart';
import 'detail-contact/contact_detail_page.dart';

/// Full ContactPage with bottom nav (for standalone use)
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ContactContent());
  }
}

/// Contact content without bottom nav (for use in MainShell)
class ContactContent extends StatefulWidget {
  const ContactContent({super.key});

  @override
  State<ContactContent> createState() => _ContactContentState();
}

class _ContactContentState extends State<ContactContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Contacts from API
  List<ContactItem> _contacts = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() => setState(() {}));
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final contacts = await _apiService.getContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ContactItem> get _filteredContacts {
    List<ContactItem> filtered = _contacts;

    // Filter by tab (0: Supplier, 1: Semua, 2: Pelanggan)
    if (_tabController.index == 0) {
      filtered = filtered.where((t) => t.type == 'SUPPLIER').toList();
    } else if (_tabController.index == 2) {
      filtered = filtered.where((t) => t.type == 'CUSTOMER').toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (t) => t.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    _buildSearchAndAction(),
                    Expanded(child: _buildContactList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Center(
        child: Text(
          'Kontak',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndAction() {
    return Column(
      children: [
        // Search Bar with Add Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari Kontak ...',
                      hintStyle: GoogleFonts.montserrat(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add Button (replacing Filter button)
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddContactModal(),
                  );

                  if (result != null) {
                    _loadContacts();
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Filter Tabs (Pelanggan, Semua, Supplier)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 3;
                return Stack(
                  children: [
                    // Sliding indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: _tabController.index * tabWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: tabWidth,
                        decoration: BoxDecoration(
                          color: _getTabColor(_tabController.index),
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                    // Tab labels
                    Row(
                      children: [
                        _buildTabLabel(0, 'Supplier'),
                        _buildTabLabel(1, 'Semua'),
                        _buildTabLabel(2, 'Pelanggan'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0: // Supplier
        return AppColors.boxSecondBack; // Green-ish for Procurement/Suppliers
      case 1: // Semua
        return AppColors.primary;
      case 2: // Pelanggan
        return AppColors.boxThird; // Red-ish for Sales/Customers
      default:
        return AppColors.primary;
    }
  }

  Widget _buildTabLabel(int index, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.index = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactList() {
    // Show skeleton loading
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: 6, // Show 6 skeleton items
        itemBuilder: (context, index) => _buildSkeletonItem(),
      );
    }

    // Show error state
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat kontak',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadContacts, child: Text('Coba lagi')),
          ],
        ),
      );
    }

    final contacts = _filteredContacts;

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada kontak',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        return _buildContactItem(contacts[index]);
      },
    );
  }

  Widget _buildContactItem(ContactItem contact) {
    final isCustomer = contact.type == 'CUSTOMER';
    final color = isCustomer ? AppColors.boxThird : AppColors.boxSecondBack;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Convert ContactItem to Map for ContactDetailPage compatibility
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactDetailPage(
              contact: {
                'id': contact.id,
                'name': contact.name,
                'type': isCustomer ? 'pelanggan' : 'supplier',
                'phone': contact.phone ?? '-',
                'address': contact.address ?? '-',
                'notes': contact.notes ?? '',
                'initial': contact.initial,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  contact.initial,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.phone ?? '-',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCustomer ? 'Pelanggan' : 'Supplier',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 16),
          // Text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Badge skeleton
          Container(
            width: 70,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
