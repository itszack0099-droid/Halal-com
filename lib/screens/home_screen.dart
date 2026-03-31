import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProductModel> _recentProducts = [];
  List<ProductModel> _haramAlerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await SupabaseService.getProducts(limit: 10);
      final haram = products.where((p) => p.isHaram).toList();
      if (mounted) {
        setState(() {
          _recentProducts = products;
          _haramAlerts = haram;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('بِسْمِ اللَّهِ',
                                style: GoogleFonts.outfit(
                                    color: AppTheme.textMuted, fontSize: 13),
                                textDirection: TextDirection.rtl),
                            const SizedBox(height: 2),
                            Text('Halal.com',
                                style: GoogleFonts.outfit(
                                    color: AppTheme.textPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceLight,
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: AppTheme.textSecondary, size: 22),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),

              // Search bar shortcut
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text('Search products, brands...',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textMuted, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
              ),

              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: [
                      _StatCard(label: 'Halal', count: '12,483', color: AppTheme.primary),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Haram', count: '3,241', color: AppTheme.haram),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Doubtful', count: '891', color: AppTheme.doubtful),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              ),

              // Haram Alerts
              if (_haramAlerts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppTheme.haram, size: 18),
                        const SizedBox(width: 8),
                        Text('Haram Alerts',
                            style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 110,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _haramAlerts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) => _HaramAlertChip(product: _haramAlerts[i]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuickAction(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan Barcode',
                            color: AppTheme.primary,
                            onTap: () => Navigator.pushNamed(context, '/scanner'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.search_rounded,
                            label: 'Search Products',
                            color: AppTheme.primaryLight,
                            onTap: () => Navigator.pushNamed(context, '/search'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.flag_outlined,
                            label: 'Report Error',
                            color: AppTheme.doubtful,
                            onTap: () => Navigator.pushNamed(context, '/report'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(),
              ),

              // Recent Products
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text('Recent Products',
                      style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                ),
              ),

              if (_loading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2),
                    ),
                  ),
                )
              else if (_recentProducts.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No products yet',
                              style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ProductCard(
                          product: _recentProducts[i],
                          index: i,
                          onTap: () => Navigator.pushNamed(context, '/product',
                              arguments: _recentProducts[i])),
                      childCount: _recentProducts.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _StatCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(count,
                style: GoogleFonts.outfit(
                    color: color, fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _HaramAlertChip extends StatelessWidget {
  final ProductModel product;
  const _HaramAlertChip({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.haram.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.haram.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, color: AppTheme.haram, size: 20),
          const SizedBox(height: 8),
          Text(product.name,
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (product.brand != null)
            Text(product.brand!,
                style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
