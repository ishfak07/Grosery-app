import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/phone_utils.dart';
import '../models/models.dart';
import 'firestore_service.dart';
import 'service_exceptions.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    required bool firebaseAvailable,
    required FirestoreService firestoreService,
  })  : _firebaseAvailable = firebaseAvailable,
        _firestoreService = firestoreService;

  final bool _firebaseAvailable;
  final FirestoreService _firestoreService;
  static const _otpTimeout = Duration(seconds: 75);

  FirebaseAuth get _auth {
    if (!_firebaseAvailable) {
      throw const FirebaseUnavailableException();
    }
    return FirebaseAuth.instance;
  }

  Stream<User?> authStateChanges() {
    if (!_firebaseAvailable) {
      return Stream<User?>.value(null);
    }
    return _auth.authStateChanges();
  }

  String hiddenEmailForPhone(String phone) {
    return PhoneUtils.hiddenEmailForPhone(phone);
  }

  bool isBootstrapAdminLogin(String phone, String password) {
    return PhoneUtils.normalizeSriLankanPhone(phone) ==
            AppConstants.bootstrapAdminPhone &&
        password == AppConstants.bootstrapAdminPassword;
  }

  bool isBootstrapAdminUser(User user) {
    return user.email?.toLowerCase() == _bootstrapAdminEmail;
  }

  UserProfile bootstrapAdminProfile(String uid) {
    final now = DateTime.now();
    return UserProfile(
      uid: uid,
      fullName: AppConstants.bootstrapAdminName,
      phone: AppConstants.bootstrapAdminPhone,
      hiddenEmail: _bootstrapAdminEmail,
      role: 'admin',
      address: '',
      createdAt: now,
      updatedAt: now,
      isPhoneVerified: true,
      isBlocked: false,
    );
  }

  String get _bootstrapAdminEmail {
    return hiddenEmailForPhone(AppConstants.bootstrapAdminPhone).toLowerCase();
  }

  Future<String> sendOtp(String phone) async {
    final normalizedPhone = PhoneUtils.normalizeSriLankanPhone(phone);
    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (!completer.isCompleted) {
            try {
              await _auth.signInWithCredential(credential);
              completer.complete('AUTO_VERIFIED');
            } catch (error, stackTrace) {
              completer.completeError(error, stackTrace);
            }
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        codeSent: (verificationId, resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );

      return await completer.future.timeout(
        _otpTimeout,
        onTimeout: () {
          throw const AuthServiceException(
            'OTP verification timed out. On an emulator, use a Firebase test phone number and test code. For real SMS, run the app on a physical phone.',
          );
        },
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase phone auth failed [${error.code}]: '
        '${error.message ?? 'No message'}',
      );
      throw AuthServiceException(_phoneAuthErrorMessage(error));
    }
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId == 'AUTO_VERIFIED') {
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_phoneAuthErrorMessage(error));
    }
  }

  Future<UserProfile> completeRegistration({
    required String fullName,
    required String phone,
    required String address,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Verify your phone number first.');
    }

    final normalizedPhone = PhoneUtils.normalizeSriLankanPhone(phone);
    final hiddenEmail = hiddenEmailForPhone(normalizedPhone);
    final credential = EmailAuthProvider.credential(
      email: hiddenEmail,
      password: password,
    );

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'provider-already-linked') {
        throw AuthServiceException(_authErrorMessage(error));
      }
    }

    await user.updateDisplayName(fullName.trim());

    final now = DateTime.now();
    final profile = UserProfile(
      uid: user.uid,
      fullName: fullName.trim(),
      phone: normalizedPhone,
      hiddenEmail: hiddenEmail,
      role: 'user',
      address: address.trim(),
      createdAt: now,
      updatedAt: now,
      isPhoneVerified: true,
      isBlocked: false,
    );

    await _firestoreService.saveUserProfile(profile);
    return profile;
  }

  Future<UserProfile> loginWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    if (isBootstrapAdminLogin(phone, password)) {
      return _loginBootstrapAdmin();
    }

    final hiddenEmail = hiddenEmailForPhone(phone);
    late final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: hiddenEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    }
    final profile = await _firestoreService.fetchUserProfile(
      credential.user!.uid,
    );
    if (profile == null) {
      throw StateError('User profile was not found in Firestore.');
    }
    if (profile.isBlocked) {
      await _auth.signOut();
      throw StateError('This account is blocked. Contact admin support.');
    }
    return profile;
  }

  Future<UserProfile> _loginBootstrapAdmin() async {
    late final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: _bootstrapAdminEmail,
        password: AppConstants.bootstrapAdminPassword,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found' &&
          error.code != 'invalid-credential') {
        throw AuthServiceException(_adminLoginErrorMessage(error));
      }

      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: _bootstrapAdminEmail,
          password: AppConstants.bootstrapAdminPassword,
        );
      } on FirebaseAuthException catch (createError) {
        throw AuthServiceException(_adminLoginErrorMessage(createError));
      }
    }

    final profile = bootstrapAdminProfile(credential.user!.uid);
    try {
      await _firestoreService.saveUserProfile(profile);
    } catch (error) {
      debugPrint('Unable to save bootstrap admin profile: $error');
    }
    return profile;
  }

  Future<void> updatePasswordAfterOtp(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Verify your phone number first.');
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    }
  }

  Future<void> logout() async {
    if (!_firebaseAvailable) {
      return;
    }
    await _auth.signOut();
  }

  @visibleForTesting
  String phoneAuthErrorMessageForTesting(FirebaseAuthException error) {
    return _phoneAuthErrorMessage(error);
  }

  String _phoneAuthErrorMessage(FirebaseAuthException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (_mentionsBillingNotEnabled(message)) {
      return 'Firebase real SMS OTP is blocked because billing is not enabled. Test phone numbers work without SMS, but real Phone Auth SMS requires Firebase billing/Blaze.';
    }

    if (_mentionsAndroidVerificationInternalError(message)) {
      return 'Firebase blocked this OTP before sending SMS. For this Android build, add the debug SHA-1 and SHA-256 fingerprints in Firebase Project settings, download the fresh google-services.json, and test real SMS on a physical phone. Android emulators should use Firebase test phone numbers.';
    }

    switch (error.code) {
      case 'operation-not-allowed':
        if (_mentionsSmsRegionPolicy(message)) {
          return 'Firebase is blocking SMS to this country. In Firebase Console, enable Authentication > Sign-in method > Phone, then allow Sri Lanka (+94) in Authentication > Settings > SMS region policy.';
        }
        if (_mentionsBillingOrPlan(message)) {
          return 'Firebase test phone numbers work because no real SMS is sent. Real OTP SMS is not available on the Firebase Spark plan; use Blaze for Firebase SMS or switch this app to a no-SMS registration flow.';
        }
        return 'Firebase blocked Phone OTP. Enable Phone in Authentication > Sign-in method, allow Sri Lanka (+94) in SMS region policy, and use Blaze for real SMS. Test phone numbers can still work because no SMS is sent.';
      case 'quota-exceeded':
        return 'Firebase SMS quota or billing limit is reached. Test phone numbers do not use SMS; real OTP SMS needs Firebase Phone Auth billing and region setup.';
      case 'app-not-authorized':
      case 'invalid-app-credential':
      case 'missing-client-identifier':
        return 'Firebase rejected this Android app for Phone OTP. Add the SHA-1 and SHA-256 fingerprints for com.ishi.grocerydelivery in Firebase Project settings, then download a fresh google-services.json.';
      default:
        return _authErrorMessage(error);
    }
  }

  bool _mentionsSmsRegionPolicy(String message) {
    return message.contains('sms region') ||
        message.contains('region policy') ||
        (message.contains('region') && message.contains('sms')) ||
        message.contains('country') && message.contains('sms');
  }

  bool _mentionsBillingOrPlan(String message) {
    return message.contains('spark') ||
        message.contains('blaze') ||
        message.contains('billing') ||
        message.contains('payment') ||
        message.contains('pay-as-you-go') ||
        message.contains('pay as you go') ||
        message.contains('not applicable');
  }

  bool _mentionsBillingNotEnabled(String message) {
    return message.contains('billing_not_enabled') ||
        message.contains('billing not enabled') ||
        message.contains('billing-not-enabled');
  }

  bool _mentionsAndroidVerificationInternalError(String message) {
    return message.contains('error code:39') ||
        message.contains('error code:-39') ||
        message.contains('status code: 17499') ||
        message.contains('unknown status code: 17499');
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter the 9 digits after +94, for example 768976222.';
      case 'too-many-requests':
        return 'Too many OTP attempts. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'Firebase SMS quota is exceeded. Check Firebase Authentication usage and billing.';
      case 'invalid-verification-code':
        return 'The OTP code is incorrect. Check the SMS and try again.';
      case 'session-expired':
        return 'The OTP expired. Request a new code.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'captcha-check-failed':
      case 'web-context-cancelled':
      case 'web-context-already-presented':
        return 'Firebase opened browser verification but it failed. On an emulator, use a Firebase test phone number and test code. For real SMS, run on a physical phone.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Phone number or password is incorrect.';
      case 'operation-not-allowed':
        return 'Firebase sign-in is disabled. Enable Phone and Email/Password in Authentication > Sign-in method.';
      default:
        return error.message ?? 'Firebase authentication failed. Try again.';
    }
  }

  String _adminLoginErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'Enable Email/Password in Firebase Authentication > Sign-in method to use the admin login without OTP.';
      case 'email-already-in-use':
      case 'invalid-credential':
      case 'wrong-password':
        return 'The admin auth account already exists with a different password. Reset it in Firebase Authentication or delete that user and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try admin login again.';
      default:
        return error.message ?? 'Admin login failed. Try again.';
    }
  }
}
