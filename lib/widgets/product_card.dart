import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import 'halal_badge.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.index = 0,
  });

  Color get _statusColor {
    switch (product.status) {
      case 'halal':
        return AppTheme.primary;
      case 'haram':
        return AppTheme.haram;
      default:
        return AppTheme.doubtful;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            // Product image/icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brand != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.brand!,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            HalalBadge(status: product.status, size: BadgeSize.small),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0),
    );
  }

  Widget _buildPlaceholder() {
    final icons = {'halal': '🥗', 'haram': '🚫', 'doubtful': '❓'};
    return Center(
      child: Text(
        icons[product.status] ?? '📦',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
