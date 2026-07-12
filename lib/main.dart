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
  await SessionManager.ensureSession();

  // Initialize theme provider before running app so theme is applied immediately
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
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
          final lightTheme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.light,
            ),
            fontFamily: 'Roboto',
          );

          final darkTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.dark,
            ),
            fontFamily: 'Roboto',
          );

          return MaterialApp(
            title: 'Wassim Food',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
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
