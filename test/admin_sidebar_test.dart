import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/providers/admin_provider.dart';
import 'package:restaurant_app/providers/branch_provider.dart';
import 'package:restaurant_app/widgets/admin_sidebar.dart';

void main() {
  testWidgets('tapping admin sidebar item does not pop the current route', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final scaffoldKey = GlobalKey<ScaffoldState>();
    String? selectedItem;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => BranchProvider()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      key: scaffoldKey,
                      drawer: AdminSidebar(
                        activeItem: 'Dashboard',
                        onItemSelected: (item) {
                          selectedItem = item;
                        },
                        onLogout: () {},
                      ),
                      body: const SizedBox.shrink(),
                    ),
                  ),
                );
              },
              child: const Text('Open admin screen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open admin screen'));
    await tester.pumpAndSettle();

    expect(navigatorKey.currentState!.canPop(), isTrue);

    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    expect(selectedItem, 'Orders');
    expect(navigatorKey.currentState!.canPop(), isTrue);
  });
}
