import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/phone_utils.dart';
import '../models/models.dart';
import 'firestore_service.dart';
import 'service_exceptions.dart';

class AuthService {
  AuthService({
    required bool firebaseAvailable,
    required FirestoreService firestoreService,
  })  : _firebaseAvailable = firebaseAvailable,
        _firestoreService = firestoreService;

  final bool _firebaseAvailable;
  final FirestoreService _firestoreService;

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

  Future<String> sendOtp(String phone) async {
    final normalizedPhone = PhoneUtils.normalizeSriLankanPhone(phone);
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      verificationCompleted: (credential) async {
        if (!completer.isCompleted) {
          await _auth.signInWithCredential(credential);
          completer.complete('AUTO_VERIFIED');
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

    return completer.future;
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
    await _auth.signInWithCredential(credential);
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
        rethrow;
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
    final hiddenEmail = hiddenEmailForPhone(phone);
    final credential = await _auth.signInWithEmailAndPassword(
      email: hiddenEmail,
      password: password,
    );
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

  Future<void> updatePasswordAfterOtp(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Verify your phone number first.');
    }
    await user.updatePassword(newPassword);
  }

  Future<void> logout() async {
    if (!_firebaseAvailable) {
      return;
    }
    await _auth.signOut();
  }
}
