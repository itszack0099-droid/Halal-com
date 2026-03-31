import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/brand_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://otsbbqlprcoadbmvgxvq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90c2JicWxwcmNvYWRibXZneHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4ODQwMDksImV4cCI6MjA5MDQ2MDAwOX0.bxp0A54tll6fYMd3_ahPt6eOGDwIBt-o1-u6FpNxBg4';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // ─── Auth ───────────────────────────────────────────────────────────────────

  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    if (res.user != null) {
      await client.from('profiles').upsert({
        'id': res.user!.id,
        'email': email,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return res;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ─── Profile ─────────────────────────────────────────────────────────────────

  static Future<UserModel?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  // ─── Products ─────────────────────────────────────────────────────────────────

  static Future<List<ProductModel>> getProducts({int limit = 20, int offset = 0}) async {
    final data = await client
        .from('products')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  static Future<List<ProductModel>> searchProducts(String query) async {
    final data = await client
        .from('products')
        .select()
        .or('name.ilike.%$query%,brand.ilike.%$query%,barcode.ilike.%$query%')
        .limit(30);
    return (data as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  static Future<ProductModel?> getProductByBarcode(String barcode) async {
    final data = await client
        .from('products')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
    if (data == null) return null;
    return ProductModel.fromJson(data);
  }

  static Future<ProductModel?> getProductById(String id) async {
    final data = await client.from('products').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return ProductModel.fromJson(data);
  }

  static Future<List<ProductModel>> getProductsByStatus(String status) async {
    final data = await client
        .from('products')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false)
        .limit(20);
    return (data as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  // ─── Brands ──────────────────────────────────────────────────────────────────

  static Future<List<BrandModel>> getBrands({int limit = 20}) async {
    final data = await client
        .from('brands')
        .select()
        .order('name')
        .limit(limit);
    return (data as List).map((e) => BrandModel.fromJson(e)).toList();
  }

  static Future<List<BrandModel>> searchBrands(String query) async {
    final data = await client
        .from('brands')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return (data as List).map((e) => BrandModel.fromJson(e)).toList();
  }

  // ─── Favorites ───────────────────────────────────────────────────────────────

  static Future<List<ProductModel>> getFavorites() async {
    final user = currentUser;
    if (user == null) return [];
    final data = await client
        .from('favorites')
        .select('products(*)')
        .eq('user_id', user.id);
    return (data as List)
        .map((e) => ProductModel.fromJson(e['products']))
        .toList();
  }

  static Future<void> addFavorite(String productId) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('favorites').upsert({
      'user_id': user.id,
      'product_id': productId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> removeFavorite(String productId) async {
    final user = currentUser;
    if (user == null) return;
    await client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('product_id', productId);
  }

  static Future<bool> isFavorite(String productId) async {
    final user = currentUser;
    if (user == null) return false;
    final data = await client
        .from('favorites')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();
    return data != null;
  }

  // ─── Reports ─────────────────────────────────────────────────────────────────

  static Future<void> submitReport({
    required String productName,
    String? barcode,
    required String issueType,
    required String details,
  }) async {
    await client.from('reports').insert({
      'user_id': currentUser?.id,
      'product_name': productName,
      'barcode': barcode,
      'issue_type': issueType,
      'details': details,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
