import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/i18n/language_codes.dart';
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

class PasswordResetStatusResult {
  const PasswordResetStatusResult({
    required this.requestId,
    required this.status,
    required this.phone,
    required this.customerName,
    required this.message,
  });

  final String requestId;
  final String status;
  final String phone;
  final String customerName;
  final String message;

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  factory PasswordResetStatusResult.fromMap(Map<dynamic, dynamic> map) {
    return PasswordResetStatusResult(
      requestId: map['requestId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      phone: map['phone']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
    );
  }
}

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

  FirebaseFunctions get _functions {
    if (!_firebaseAvailable) {
      throw const FirebaseUnavailableException();
    }
    return FirebaseFunctions.instance;
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
    if (kReleaseMode) {
      return false;
    }
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

  Future<UserProfile> completeRegistration({
    required String fullName,
    required String phone,
    required String address,
    required String password,
    required String preferredLanguageCode,
  }) async {
    final normalizedPhone = PhoneUtils.normalizeSriLankanPhone(phone);
    if (!PhoneUtils.isSriLankanMobile(normalizedPhone)) {
      throw const AuthServiceException(
        'Enter a valid Sri Lankan mobile number starting with 7.',
      );
    }

    final hiddenEmail = hiddenEmailForPhone(normalizedPhone);
    late final UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: hiddenEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_registrationErrorMessage(error));
    }

    final user = credential.user!;
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
      preferredLanguageCode: AppLanguageCodes.normalize(preferredLanguageCode),
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
    if (isBootstrapAdminUser(credential.user!)) {
      return _saveBootstrapAdminProfile(credential.user!.uid);
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
    if (kReleaseMode) {
      throw const AuthServiceException(
        'Bootstrap admin login is disabled in release builds.',
      );
    }

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

    return _saveBootstrapAdminProfile(credential.user!.uid);
  }

  Future<UserProfile> _saveBootstrapAdminProfile(String uid) async {
    final profile = bootstrapAdminProfile(uid);
    try {
      await _firestoreService.saveUserProfile(profile);
    } catch (error) {
      debugPrint('Unable to save bootstrap admin profile: $error');
    }
    return profile;
  }

  Future<PasswordResetStatusResult> requestPasswordReset(String phone) {
    return _callPasswordResetFunction(
      'requestPasswordReset',
      {'phone': PhoneUtils.normalizeSriLankanPhone(phone)},
    );
  }

  Future<PasswordResetStatusResult> fetchPasswordResetStatus(String phone) {
    return _callPasswordResetFunction(
      'getPasswordResetStatus',
      {'phone': PhoneUtils.normalizeSriLankanPhone(phone)},
    );
  }

  Future<void> completeApprovedPasswordReset({
    required String phone,
    required String newPassword,
  }) async {
    try {
      await _functions.httpsCallable('completeApprovedPasswordReset').call({
        'phone': PhoneUtils.normalizeSriLankanPhone(phone),
        'newPassword': newPassword,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> approvePasswordReset(String requestId) async {
    try {
      await _functions.httpsCallable('approvePasswordReset').call({
        'requestId': requestId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> rejectPasswordReset(String requestId) async {
    try {
      await _functions.httpsCallable('rejectPasswordReset').call({
        'requestId': requestId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> createDeliveryBoyAccount({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    await _callFirstAvailableDeliveryFunction(
      primaryName: 'createDeliveryBoyAccount',
      fallbackName: 'createDeliveryBoy',
      data: {
        'fullName': fullName.trim(),
        'phone': PhoneUtils.normalizeSriLankanPhone(phone),
        'password': password,
      },
    );
  }

  Future<void> updateDeliveryBoyAccount({
    required String uid,
    required String fullName,
    required String phone,
    String password = '',
    bool? isActive,
  }) async {
    final data = <String, Object?>{
      'uid': uid,
      'fullName': fullName.trim(),
      'phone': PhoneUtils.normalizeSriLankanPhone(phone),
      'password': password,
    };
    if (isActive != null) {
      data['isActive'] = isActive;
      data['isBlocked'] = !isActive;
    }
    await _callFirstAvailableDeliveryFunction(
      primaryName: 'updateDeliveryBoyAccount',
      fallbackName: 'updateDeliveryBoy',
      data: data,
    );
  }

  Future<void> setDeliveryBoyActive({
    required String uid,
    required bool isActive,
  }) async {
    try {
      await _functions.httpsCallable('setDeliveryBoyActive').call({
        'uid': uid,
        'isActive': isActive,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> createDeliveryBoy({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    await createDeliveryBoyAccount(
      fullName: fullName,
      phone: phone,
      password: password,
    );
  }

  Future<void> updateDeliveryBoy({
    required String uid,
    required String fullName,
    required String phone,
    String? password,
    required bool isBlocked,
  }) async {
    await updateDeliveryBoyAccount(
      uid: uid,
      fullName: fullName,
      phone: phone,
      password: password ?? '',
      isActive: !isBlocked,
    );
  }

  Future<void> markAssignedOrderDelivered(String orderId) async {
    try {
      await _functions.httpsCallable('markAssignedOrderDelivered').call({
        'orderId': orderId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> submitDeliveryReview({
    required String orderId,
    required int rating,
    required String review,
  }) async {
    try {
      await _functions.httpsCallable('submitDeliveryReview').call({
        'orderId': orderId,
        'rating': rating,
        'review': review.trim(),
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> initializeDeliveryRewardStars({String? uid}) async {
    try {
      await _functions.httpsCallable('initializeDeliveryRewardStars').call({
        if (uid != null) 'uid': uid,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> payDeliveryStarReward({
    required String uid,
    required int amountLkr,
  }) async {
    try {
      await _functions.httpsCallable('payDeliveryStarReward').call({
        'uid': uid,
        'amountLkr': amountLkr,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> addDeliveryRewardStars({
    required String uid,
    required int stars,
  }) async {
    try {
      await _functions.httpsCallable('addDeliveryRewardStars').call({
        'uid': uid,
        'stars': stars,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> _callFirstAvailableDeliveryFunction({
    required String primaryName,
    required String fallbackName,
    required Map<String, Object?> data,
  }) async {
    try {
      await _functions.httpsCallable(primaryName).call(data);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found') {
        throw AuthServiceException(_functionsErrorMessage(error));
      }
      try {
        await _functions.httpsCallable(fallbackName).call(data);
      } on FirebaseFunctionsException catch (fallbackError) {
        if (fallbackError.code == 'not-found') {
          throw const AuthServiceException(
            'Delivery boy account service is not deployed. Deploy Firebase Functions and try again.',
          );
        }
        throw AuthServiceException(_functionsErrorMessage(fallbackError));
      }
    }
  }

  Future<PasswordResetStatusResult> _callPasswordResetFunction(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      return PasswordResetStatusResult.fromMap(
        result.data as Map<dynamic, dynamic>,
      );
    } on FirebaseFunctionsException catch (error) {
      throw AuthServiceException(_functionsErrorMessage(error));
    }
  }

  Future<void> logout() async {
    if (!_firebaseAvailable) {
      return;
    }
    await _auth.signOut();
  }

  String _registrationErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this phone number. Login or request a password reset.';
      default:
        return _authErrorMessage(error);
    }
  }

  String _functionsErrorMessage(FirebaseFunctionsException error) {
    final message = error.message;
    switch (error.code) {
      case 'invalid-argument':
        return message ?? 'Check the details and try again.';
      case 'not-found':
        return message ?? 'No account was found for that phone number.';
      case 'failed-precondition':
        return message ?? 'This request is not ready yet.';
      case 'permission-denied':
      case 'unauthenticated':
        return message ?? 'You are not allowed to perform this action.';
      case 'unavailable':
        return message ?? 'Service is unavailable. Try again shortly.';
      default:
        return message ?? 'Request failed. Try again.';
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter the 9 digits after +94, for example 768976222.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'Firebase authentication quota is exceeded. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Phone number or password is incorrect.';
      case 'operation-not-allowed':
        return 'Firebase sign-in is disabled. Enable Email/Password in Authentication > Sign-in method.';
      case 'user-disabled':
        return 'This account is deactivated. Contact admin support.';
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
