import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/utils/phone_utils.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/auth_service.dart';

void main() {
  test('normalizes Sri Lankan phone numbers from local input', () {
    expect(
      PhoneUtils.normalizeSriLankanPhone('770000000'),
      '+94770000000',
    );
    expect(
      PhoneUtils.normalizeSriLankanPhone('0770000000'),
      '+94770000000',
    );
    expect(
      PhoneUtils.localSriLankanDigits('+94770000000'),
      '770000000',
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
