import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getProfile();
      if (mounted) setState(() { _user = profile; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.outfit(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.haram,
                minimumSize: const Size(0, 40)),
            child: Text('Sign Out', style: GoogleFonts.outfit(fontSize: 14)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supaUser = SupabaseService.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Avatar
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryDark, AppTheme.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              (_user?.name ?? supaUser?.email ?? 'G')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ).animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),
                        const SizedBox(height: 14),
                        Text(
                          _user?.displayName ?? supaUser?.email?.split('@').first ?? 'User',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ).animate(delay: 100.ms).fadeIn(),
                        const SizedBox(height: 4),
                        Text(
                          supaUser?.email ?? '',
                          style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
                        ).animate(delay: 150.ms).fadeIn(),
                        const SizedBox(height: 28),

                        // Stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(label: 'Favorites', value: '0'),
                                Container(width: 1, height: 30, color: AppTheme.cardBorder),
                                _StatItem(label: 'Reports', value: '0'),
                                Container(width: 1, height: 30, color: AppTheme.cardBorder),
                                _StatItem(label: 'Scans', value: '0'),
                              ],
                            ),
                          ),
                        ).animate(delay: 200.ms).fadeIn(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),

                  // Menu items
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _MenuItem(
                          icon: Icons.flag_outlined,
                          label: 'Report a Product',
                          onTap: () => Navigator.pushNamed(context, '/report'),
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          trailing: Switch(
                            value: true,
                            onChanged: (_) {},
                            activeColor: AppTheme.primary,
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          trailing: Switch(
                            value: true,
                            onChanged: (_) {},
                            activeColor: AppTheme.primary,
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.info_outline_rounded,
                          label: 'About Halal.com',
                          onTap: () => showAboutDialog(
                            context: context,
                            applicationName: 'Halal.com',
                            applicationVersion: '1.0.0',
                            applicationLegalese: 'Built by Halalbillionaires\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MenuItem(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          labelColor: AppTheme.haram,
                          iconColor: AppTheme.haram,
                          onTap: _signOut,
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? labelColor;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.outfit(
                      color: labelColor ?? AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            trailing ?? (onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 20)
                : const SizedBox()),
          ],
        ),
      ),
    );
  }
}
