import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/branch_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/cart_screen.dart';
import 'utils/helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.ensureSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      ],
      child: MaterialApp(
        title: 'Wassim Food',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
        routes: {
          CartScreen.routeName: (ctx) => const CartScreen(),
        },
      ),
    );
  }
}
