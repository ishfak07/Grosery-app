import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/utils/phone_utils.dart';
import 'package:grocerydelivery/src/services/auth_service.dart';
import 'package:grocerydelivery/src/services/firestore_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService(
      firebaseAvailable: false,
      firestoreService: FirestoreService(firebaseAvailable: false),
    );
  });

  test('explains SMS region policy blocks', () {
    final message = authService.phoneAuthErrorMessageForTesting(
      FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'SMS unable to be sent until this region is enabled.',
      ),
    );

    expect(message, contains('allow Sri Lanka (+94)'));
    expect(message, contains('SMS region policy'));
  });

  test('explains Spark plan real SMS blocks', () {
    final message = authService.phoneAuthErrorMessageForTesting(
      FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Phone Auth SMS is not applicable on the Spark plan.',
      ),
    );

    expect(message, contains('test phone numbers work'));
    expect(message, contains('Real OTP SMS is not available'));
  });

  test('explains Firebase billing-not-enabled phone auth errors', () {
    final message = authService.phoneAuthErrorMessageForTesting(
      FirebaseAuthException(
        code: 'unknown',
        message: 'An internal error has occurred. [ BILLING_NOT_ENABLED ]',
      ),
    );

    expect(message, contains('billing is not enabled'));
    expect(message, contains('real Phone Auth SMS requires'));
  });

  test('explains Android app verification setup blocks', () {
    final message = authService.phoneAuthErrorMessageForTesting(
      FirebaseAuthException(code: 'app-not-authorized'),
    );

    expect(message, contains('SHA-1 and SHA-256'));
    expect(message, contains('google-services.json'));
  });

  test('explains Firebase phone auth quota error 39', () {
    final message = authService.phoneAuthErrorMessageForTesting(
      FirebaseAuthException(
        code: 'unknown',
        message: 'An internal error has occurred. [ Error code:39 ]',
      ),
    );

    expect(message, contains('before sending SMS'));
    expect(message, contains('Auth quota or fraud limit'));
    expect(message, contains('Sign-up quota'));
  });

  test('explains reCAPTCHA setup blocks after SHA setup', () {
    final message = authService.phoneAuthErrorMessageForTesting(
      FirebaseAuthException(
        code: 'unknown',
        message: 'reCAPTCHA failed because the API key is not authorized.',
      ),
    );

    expect(message, contains('reCAPTCHA app verification failed'));
    expect(message, contains('grocery-delivery-app-388bc.firebaseapp.com'));
  });

  test('recognizes the bootstrap admin login only with the fixed password', () {
    expect(
      authService.isBootstrapAdminLogin('+94768976111', 'admin123'),
      isTrue,
    );
    expect(
      authService.isBootstrapAdminLogin('0768976111', 'admin123'),
      isTrue,
    );
    expect(
      authService.isBootstrapAdminLogin('+94768976111', 'wrong'),
      isFalse,
    );
  });

  test('normalizes Sri Lankan phone numbers from local input', () {
    expect(
      PhoneUtils.normalizeSriLankanPhone('768976111'),
      '+94768976111',
    );
    expect(
      PhoneUtils.normalizeSriLankanPhone('0768976111'),
      '+94768976111',
    );
    expect(
      PhoneUtils.localSriLankanDigits('+94768976111'),
      '768976111',
    );
  });

  test('builds an admin profile for the bootstrap admin user', () {
    final profile = authService.bootstrapAdminProfile('admin-uid');

    expect(profile.uid, 'admin-uid');
    expect(profile.phone, '+94768976111');
    expect(profile.hiddenEmail, '94768976111@app.local');
    expect(profile.role, 'admin');
    expect(profile.isAdmin, isTrue);
    expect(profile.isPhoneVerified, isTrue);
  });
}
