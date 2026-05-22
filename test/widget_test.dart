import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/app.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows onboarding when logged out', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(
          const FirebaseBootstrap(
            isReady: false,
            errorMessage: 'Firebase unavailable in widget test',
          ),
        )..initialize(),
        child: const GroceryDeliveryApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Order from trusted local shops'), findsOneWidget);
  });
}
