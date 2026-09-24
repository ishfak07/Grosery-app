import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/features/admin/admin_screens.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  for (final size in const [Size(360, 800), Size(412, 915), Size(1280, 900)]) {
    testWidgets(
        'admin dashboard lays out without overflow at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: _DashboardTestAppState(),
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      // The live-status dot pulses forever, so settle with fixed pumps.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Total orders'), findsOneWidget);

      // Every dashboard shortcut is still reachable.
      final scrollable = find.byType(Scrollable).first;
      for (final title in const [
        'Orders',
        'Find order',
        'Accounts',
        'Checkout',
        'Products',
        'Quick prices',
        'Offers',
        'Categories',
        'Customers',
        'Delivery boys',
        'Password resets',
        'Admin Account',
        'Account deletion',
        'Support',
        'Broadcast',
        'No pending orders',
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          200,
          scrollable: scrollable,
        );
        expect(find.text(title), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _DashboardTestAppState extends AppState {
  _DashboardTestAppState()
      : super(
          const FirebaseBootstrap(
            isReady: false,
            errorMessage: 'Firebase unavailable in dashboard layout test',
          ),
        );

  @override
  UserProfile? get profile => UserProfile(
        uid: 'admin-1',
        fullName: 'Admin',
        phone: '+94770000001',
        hiddenEmail: '94770000001@app.local',
        role: 'admin',
        address: 'Puttalam',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isPhoneVerified: true,
        isBlocked: false,
      );

  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => true;
}
