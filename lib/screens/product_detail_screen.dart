import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../services/groq_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/halal_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  String? _aiAnalysis;
  bool _loadingAI = false;
  bool _loadingFav = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final product = ModalRoute.of(context)?.settings.arguments as ProductModel?;
    if (product != null) {
      _checkFavorite(product.id);
      if (product.ingredients != null && product.ingredients!.isNotEmpty) {
        _loadAI(product);
      }
    }
  }

  Future<void> _checkFavorite(String id) async {
    final fav = await SupabaseService.isFavorite(id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _loadAI(ProductModel product) async {
    if (product.ingredients == null || product.ingredients!.isEmpty) return;
    setState(() => _loadingAI = true);
    final analysis = await GroqService.analyzeIngredients(
        product.name, product.ingredients!);
    if (mounted) setState(() { _aiAnalysis = analysis; _loadingAI = false; });
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() => _loadingFav = true);
    try {
      if (_isFavorite) {
        await SupabaseService.removeFavorite(id);
      } else {
        await SupabaseService.addFavorite(id);
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (_) {}
    if (mounted) setState(() => _loadingFav = false);
  }

  Color get _statusColor {
    final product = ModalRoute.of(context)?.settings.arguments as ProductModel?;
    switch (product?.status) {
      case 'halal': return AppTheme.primary;
      case 'haram': return AppTheme.haram;
      default: return AppTheme.doubtful;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)?.settings.arguments as ProductModel?;
    if (product == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _loadingFav
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                  : IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? AppTheme.haram : AppTheme.textMuted,
                      ),
                      onPressed: () => _toggleFavorite(product.id),
                    ),
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: AppTheme.textMuted),
                onPressed: () => Navigator.pushNamed(context, '/report'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _statusColor.withOpacity(0.12),
                      AppTheme.background,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: _statusColor.withOpacity(0.3), width: 1.5),
                      ),
                      child: product.imageUrl != null
                          ? ClipOval(
                              child: Image.network(product.imageUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                      child: Text('📦', style: TextStyle(fontSize: 36)))))
                          : const Center(child: Text('📦', style: TextStyle(fontSize: 36))),
                    ).animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),
                    const SizedBox(height: 12),
                    HalalBadge(status: product.status, size: BadgeSize.large),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700))
                      .animate().fadeIn().slideY(begin: 0.2),
                  if (product.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(product.brand!,
                        style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 15))
                        .animate(delay: 100.ms).fadeIn(),
                  ],
                  if (product.barcode != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.qr_code, color: AppTheme.textMuted, size: 14),
                        const SizedBox(width: 6),
                        Text(product.barcode!,
                            style: GoogleFonts.outfit(
                                color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
                      ],
                    ).animate(delay: 150.ms).fadeIn(),
                  ],
                  const SizedBox(height: 20),

                  // Status card
                  if (product.reason != null)
                    _InfoCard(
                      title: 'Why ${product.status.toUpperCase()}?',
                      child: Text(product.reason!,
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
                      borderColor: _statusColor,
                    ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 14),

                  // Ingredients
                  if (product.ingredients != null && product.ingredients!.isNotEmpty)
                    _InfoCard(
                      title: 'Ingredients',
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: product.ingredients!.map((ing) {
                          final isConcern = _isConcernIngredient(ing);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isConcern
                                  ? AppTheme.haram.withOpacity(0.1)
                                  : AppTheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isConcern
                                    ? AppTheme.haram.withOpacity(0.3)
                                    : AppTheme.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Text(ing,
                                style: GoogleFonts.outfit(
                                    color: isConcern ? AppTheme.haramLight : AppTheme.textSecondary,
                                    fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 14),

                  // AI Analysis
                  _InfoCard(
                    title: '🤖 AI Analysis',
                    subtitle: 'Powered by LLaMA 3.1 · Groq',
                    borderColor: AppTheme.primary.withOpacity(0.3),
                    child: _loadingAI
                        ? Row(
                            children: [
                              const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5, color: AppTheme.primary)),
                              const SizedBox(width: 12),
                              Text('Analyzing ingredients...',
                                  style: GoogleFonts.outfit(
                                      color: AppTheme.textMuted, fontSize: 13)),
                            ],
                          )
                        : _aiAnalysis != null
                            ? Text(_aiAnalysis!,
                                style: GoogleFonts.outfit(
                                    color: AppTheme.textSecondary, fontSize: 14, height: 1.5))
                            : Text(
                                product.ingredients == null || product.ingredients!.isEmpty
                                    ? 'No ingredient data available for analysis.'
                                    : 'Analysis unavailable at this time.',
                                style: GoogleFonts.outfit(
                                    color: AppTheme.textMuted, fontSize: 13)),
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isConcernIngredient(String ing) {
    const concerns = ['gelatin', 'pork', 'lard', 'alcohol', 'wine', 'beer',
        'rum', 'vanilla extract', 'pepperoni', 'ham', 'bacon'];
    return concerns.any((c) => ing.toLowerCase().contains(c));
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? borderColor;

  const _InfoCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              if (subtitle != null) ...[
                const Spacer(),
                Text(subtitle!,
                    style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
