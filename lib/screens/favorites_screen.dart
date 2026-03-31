import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<ProductModel> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    try {
      final favs = await SupabaseService.getFavorites();
      if (mounted) setState(() => _favorites = favs);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFavorites,
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    children: [
                      Text('My Favorites',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (_favorites.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Text('${_favorites.length}',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ).animate().fadeIn(),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2)),
                )
              else if (_favorites.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('❤️', style: TextStyle(fontSize: 56))
                            .animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),
                        const SizedBox(height: 16),
                        Text('No favorites yet',
                            style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600))
                            .animate(delay: 100.ms).fadeIn(),
                        const SizedBox(height: 8),
                        Text(
                          'Tap ❤️ on any product\nto save it here',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textMuted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ).animate(delay: 200.ms).fadeIn(),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/search'),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: Text('Browse Products',
                              style: GoogleFonts.outfit(fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 48)),
                        ).animate(delay: 300.ms).fadeIn(),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ProductCard(
                        product: _favorites[i],
                        index: i,
                        onTap: () => Navigator.pushNamed(context, '/product',
                            arguments: _favorites[i]).then((_) => _loadFavorites()),
                      ),
                      childCount: _favorites.length,
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
