import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/utils/phone_utils.dart';
import 'package:grocerydelivery/src/models/models.dart';
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
    expect(PhoneUtils.isSriLankanMobile('+94788731444'), isTrue);
    expect(PhoneUtils.isSriLankanMobile('011234567'), isFalse);
  });

  test('parses password reset callable status payloads', () {
    final status = PasswordResetStatusResult.fromMap({
      'requestId': 'request-1',
      'status': 'approved',
      'phone': '+94788731444',
      'customerName': 'Nimal',
      'message': 'Admin approved your reset. Set a new password.',
    });

    expect(status.requestId, 'request-1');
    expect(status.isApproved, isTrue);
    expect(status.phone, '+94788731444');
    expect(status.customerName, 'Nimal');
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

  test('uses the Firestore document id as the user profile uid', () {
    final profile = UserProfile.fromMap({
      'uid': 'stale-user-id',
      'fullName': 'Customer',
      'phone': '+94788731444',
      'hiddenEmail': '94788731444@app.local',
      'role': 'user',
      'address': 'Puttalam',
      'isPhoneVerified': true,
      'isBlocked': false,
    }, 'auth-user-id');

    expect(profile.uid, 'auth-user-id');
  });
}
