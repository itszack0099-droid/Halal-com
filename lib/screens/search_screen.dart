import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/brand_model.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  List<ProductModel> _products = [];
  List<BrandModel> _brands = [];
  bool _loading = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final products = await SupabaseService.getProducts(limit: 30);
      final brands = await SupabaseService.getBrands(limit: 30);
      if (mounted) setState(() { _products = products; _brands = brands; });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) { _loadAll(); return; }
    setState(() => _loading = true);
    try {
      final products = await SupabaseService.searchProducts(query);
      final brands = await SupabaseService.searchBrands(query);
      if (mounted) setState(() { _products = products; _brands = brands; });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<ProductModel> get _filteredProducts {
    if (_filter == 'all') return _products;
    return _products.where((p) => p.status == _filter).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Search',
                  style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
            ).animate().fadeIn(),

            // Search input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _search,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Products, brands, barcodes...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.textMuted, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadAll();
                          },
                        )
                      : null,
                ),
                autofocus: true,
              ),
            ).animate(delay: 100.ms).fadeIn(),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'All', value: 'all', current: _filter,
                      onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '🟢 Halal', value: 'halal', current: _filter,
                      onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '🔴 Haram', value: 'haram', current: _filter,
                      onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '🟡 Doubtful', value: 'doubtful', current: _filter,
                      onTap: (v) => setState(() => _filter = v)),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
                tabs: const [Tab(text: 'Products'), Tab(text: 'Brands')],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Products tab
                        _filteredProducts.isEmpty
                            ? _buildEmpty('No products found')
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (ctx, i) => ProductCard(
                                  product: _filteredProducts[i],
                                  index: i,
                                  onTap: () => Navigator.pushNamed(
                                      context, '/product',
                                      arguments: _filteredProducts[i]),
                                ),
                              ),
                        // Brands tab
                        _brands.isEmpty
                            ? _buildEmpty('No brands found')
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _brands.length,
                                itemBuilder: (ctx, i) => _BrandCard(
                                    brand: _brands[i], index: i),
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(msg, style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 15)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Function(String) onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.cardBorder,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final BrandModel brand;
  final int index;

  const _BrandCard({required this.brand, required this.index});

  Color get _statusColor {
    switch (brand.status) {
      case 'halal': return AppTheme.primary;
      case 'haram': return AppTheme.haram;
      default: return AppTheme.doubtful;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _statusColor.withOpacity(0.3)),
            ),
            child: Icon(Icons.business_rounded, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brand.name,
                    style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (brand.country != null)
                  Text(brand.country!,
                      style: GoogleFonts.outfit(
                          color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withOpacity(0.4)),
            ),
            child: Text(brand.status.toUpperCase(),
                style: GoogleFonts.outfit(
                    color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideX(begin: 0.05);
  }
}
