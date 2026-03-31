import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/scan_result_model.dart';
import '../services/open_food_facts_service.dart';
import '../theme/app_theme.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final product = args?['product'] as OpenFoodFactsProduct?;
    final aiResult = args?['aiResult'] as AiAnalysisResult?;

    if (product == null || aiResult == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text('No result data',
              style: GoogleFonts.outfit(color: AppTheme.textMuted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (_) => false),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: AppTheme.textSecondary, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Scan Result',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/scanner'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded,
                            color: AppTheme.primary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildContent(context, product, aiResult)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OpenFoodFactsProduct product,
    AiAnalysisResult aiResult,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Product Info Card ──────────────────────────
          _ProductCard(product: product)
              .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // ── Status Card (hero) ─────────────────────────
          _StatusCard(result: aiResult)
              .animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // ── Reason Card ───────────────────────────────
          _ReasonCard(result: aiResult)
              .animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15),

          const SizedBox(height: 16),

          // ── Haram/Doubtful Flags ──────────────────────
          if (aiResult.haramIngredients.isNotEmpty)
            _FlaggedCard(
              title: 'Haram Ingredients',
              items: aiResult.haramIngredients,
              color: AppTheme.haram,
              icon: Icons.block_rounded,
            ).animate(delay: 320.ms).fadeIn(),

          if (aiResult.doubtfulIngredients.isNotEmpty) ...[
            const SizedBox(height: 10),
            _FlaggedCard(
              title: 'Doubtful Ingredients',
              items: aiResult.doubtfulIngredients,
              color: AppTheme.doubtful,
              icon: Icons.help_outline_rounded,
            ).animate(delay: 360.ms).fadeIn(),
          ],

          if (aiResult.haramIngredients.isNotEmpty ||
              aiResult.doubtfulIngredients.isNotEmpty)
            const SizedBox(height: 16),

          // ── Full Ingredients ─────────────────────────
          if (product.ingredientsText != null)
            _IngredientsCard(
              text: product.ingredientsText!,
              ingredients: product.ingredients,
              haramList: aiResult.haramIngredients,
              doubtfulList: aiResult.doubtfulIngredients,
            ).animate(delay: 400.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── Action Buttons ───────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Scan Again',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () => Navigator.pushReplacementNamed(context, '/scanner'),
                  outlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Report Error',
                  icon: Icons.flag_outlined,
                  onTap: () => Navigator.pushNamed(context, '/report'),
                  outlined: true,
                ),
              ),
            ],
          ).animate(delay: 450.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Product Info Card ──────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final OpenFoodFactsProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 14),
          // Name + brand
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.brand!,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (product.country != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppTheme.textMuted, size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product.country!.split(',').first.trim(),
                          style: GoogleFonts.outfit(
                              color: AppTheme.textMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  product.barcode,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppTheme.surfaceLight,
      child: const Center(child: Text('📦', style: TextStyle(fontSize: 32))),
    );
  }
}

// ── Status Card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final AiAnalysisResult result;
  const _StatusCard({required this.result});

  Color get _color {
    switch (result.status) {
      case 'halal': return AppTheme.primary;
      case 'haram': return AppTheme.haram;
      default: return AppTheme.doubtful;
    }
  }

  String get _emoji {
    switch (result.status) {
      case 'halal': return '✅';
      case 'haram': return '🚫';
      default: return '⚠️';
    }
  }

  String get _label => result.status.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 52))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05),
                  duration: 1500.ms, curve: Curves.easeInOut),
          const SizedBox(height: 14),
          Text(
            _label,
            style: GoogleFonts.outfit(
              color: _color,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          // Confidence bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Confidence',
                    style: GoogleFonts.outfit(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                  Text(
                    '${result.confidencePercent}%',
                    style: GoogleFonts.outfit(
                        color: _color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.confidence,
                  backgroundColor: _color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🤖 Powered by Groq · LLaMA 3.1',
            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Reason Card ────────────────────────────────────────────────────────────────

class _ReasonCard extends StatelessWidget {
  final AiAnalysisResult result;
  const _ReasonCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANALYSIS',
            style: GoogleFonts.outfit(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.reason,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flagged Ingredients Card ───────────────────────────────────────────────────

class _FlaggedCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;

  const _FlaggedCard({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                item,
                style: GoogleFonts.outfit(color: color, fontSize: 12),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Full Ingredients Card ─────────────────────────────────────────────────────

class _IngredientsCard extends StatefulWidget {
  final String text;
  final List<String> ingredients;
  final List<String> haramList;
  final List<String> doubtfulList;

  const _IngredientsCard({
    required this.text,
    required this.ingredients,
    required this.haramList,
    required this.doubtfulList,
  });

  @override
  State<_IngredientsCard> createState() => _IngredientsCardState();
}

class _IngredientsCardState extends State<_IngredientsCard> {
  bool _expanded = false;

  Color _ingredientColor(String ing) {
    final lower = ing.toLowerCase();
    if (widget.haramList.any((h) => lower.contains(h.toLowerCase()))) {
      return AppTheme.haram;
    }
    if (widget.doubtfulList.any((d) => lower.contains(d.toLowerCase()))) {
      return AppTheme.doubtful;
    }
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'INGREDIENTS',
                style: GoogleFonts.outfit(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show all',
                  style: GoogleFonts.outfit(
                      color: AppTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.ingredients.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ((_expanded
                  ? widget.ingredients
                  : widget.ingredients.take(8).toList()))
                  .map((ing) {
                final color = _ingredientColor(ing);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Text(
                    ing,
                    style: GoogleFonts.outfit(color: color, fontSize: 12),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              widget.text,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: _expanded ? null : 4,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.fade,
            ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: outlined ? AppTheme.cardBorder : AppTheme.primary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: outlined ? AppTheme.textSecondary : Colors.white,
                size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: outlined ? AppTheme.textSecondary : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
