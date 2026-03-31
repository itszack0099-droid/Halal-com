import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/report_screen.dart';
import 'screens/scan_result_screen.dart';
import 'widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Hive
  await Hive.initFlutter();

  // Supabase (hardcoded credentials)
  await SupabaseService.initialize();

  runApp(const HalalApp());
}

class HalalApp extends StatelessWidget {
  const HalalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halal.com',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const MainNavigator(),
        '/search': (_) => const MainNavigator(initialIndex: 1),
        '/scanner': (_) => const ScannerScreen(),
        '/product': (_) => const ProductDetailScreen(),
        '/favorites': (_) => const MainNavigator(initialIndex: 3),
        '/profile': (_) => const MainNavigator(initialIndex: 4),
        '/report': (_) => const ReportScreen(),
        '/scan-result': (_) => const ScanResultScreen(),
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  final int initialIndex;

  const MainNavigator({super.key, this.initialIndex = 0});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  late int _currentIndex;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    ScannerScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    if (index == 2) {
      // Scanner as full-screen
      Navigator.pushNamed(context, '/scanner');
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final displayIndex = _currentIndex == 2 ? 0 : _currentIndex;
    final navIndex = _currentIndex >= 3 ? _currentIndex : _currentIndex;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: displayIndex < 2 ? displayIndex : displayIndex - 1,
        children: [
          _screens[0], // Home
          _screens[1], // Search
          _screens[3], // Favorites (index 3 maps to display index 2)
          _screens[4], // Profile (index 4 maps to display index 3)
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: navIndex >= 3 ? navIndex : navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
