import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/branch_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/client_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/offers_provider.dart';
import 'providers/category_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/category_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/branch_selection_screen.dart';
import 'screens/offers_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/client_login_screen.dart';
import 'screens/client_register_screen.dart';
import 'screens/client_profile_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/ai_food_assistant_screen.dart';
import 'utils/helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Parallelize session initialization and theme loading to speed up startup
  final themeProvider = ThemeProvider();
  await Future.wait([
    SessionManager.ensureSession(),
    themeProvider.loadTheme(),
  ]);

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8D4B38),
      primary: const Color(0xFF8D4B38),
      secondary: const Color(0xFFFFB703),
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF8D4B38),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8D4B38), width: 1.5),
      ),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8D4B38),
      primary: const Color(0xFF8D4B38),
      secondary: const Color(0xFFFFB703),
      surface: const Color(0xFF1E293B),
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF8D4B38),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8D4B38), width: 1.5),
      ),
    ),
  );

  const MyApp({Key? key, required this.themeProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProxyProvider<BranchProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, branchProvider, cartProvider) =>
              cartProvider!..updateBranch(branchProvider.selectedBranch),
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => OffersProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return MaterialApp(
            title: 'Wassim Food',
            debugShowCheckedModeBanner: false,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: themeProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              final name = settings.name;
              if (name != null && name.startsWith('/menu/')) {
                final slug = name.substring('/menu/'.length);
                if (slug.isNotEmpty) {
                  return MaterialPageRoute(
                    builder: (context) {
                      // Schedule branch selection after frame
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        final branchProv = context.read<BranchProvider>();
                        await branchProv.selectBranchById(slug);
                        if (branchProv.selectedBranch != null) {
                          context.read<MenuProvider>().loadMenu(branchProv.selectedBranch!.id);
                        }
                      });
                      return const MenuScreen();
                    },
                    settings: settings,
                  );
                }
              }
              return null; // Fallback to routes map
            },
            routes: {
              HomeScreen.routeName: (ctx) => const HomeScreen(),
              BranchSelectionScreen.routeName: (ctx) => const BranchSelectionScreen(),
              OffersScreen.routeName: (ctx) => const OffersScreen(),
              FavoritesScreen.routeName: (ctx) => const FavoritesScreen(),
              CartScreen.routeName: (ctx) => const CartScreen(),
              AdminLoginScreen.routeName: (ctx) => const AdminLoginScreen(),
              AdminDashboardScreen.routeName: (ctx) => const AdminDashboardScreen(),
              ClientLoginScreen.routeName: (ctx) => const ClientLoginScreen(),
              ClientRegisterScreen.routeName: (ctx) => const ClientRegisterScreen(),
              ClientProfileScreen.routeName: (ctx) => const ClientProfileScreen(),
              NotificationScreen.routeName: (ctx) => const NotificationScreen(),
              OrdersScreen.routeName: (ctx) => const OrdersScreen(),
              MenuScreen.routeName: (ctx) => const MenuScreen(),
              AiFoodAssistantScreen.routeName: (ctx) => const AiFoodAssistantScreen(),
            },
          );
        },
      ),
    );
  }
}
