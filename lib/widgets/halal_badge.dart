import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

enum BadgeSize { small, medium, large }

class HalalBadge extends StatelessWidget {
  final String status;
  final BadgeSize size;
  final bool showIcon;

  const HalalBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.medium,
    this.showIcon = true,
  });

  Color get _color {
    switch (status.toLowerCase()) {
      case 'halal':
        return AppTheme.primary;
      case 'haram':
        return AppTheme.haram;
      default:
        return AppTheme.doubtful;
    }
  }

  String get _icon {
    switch (status.toLowerCase()) {
      case 'halal':
        return '✓';
      case 'haram':
        return '✗';
      default:
        return '?';
    }
  }

  String get _label => status.toUpperCase();

  double get _fontSize {
    switch (size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.large:
        return 15;
      default:
        return 12;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 3);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 8);
      default:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text(
              _icon,
              style: TextStyle(
                color: _color,
                fontSize: _fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
