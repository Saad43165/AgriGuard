import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Global notifier – keep it if the rest of your app already uses it.
ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------------------------------------------------
  //  BASIC GETTERS
  // -----------------------------------------------------------------
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  // -----------------------------------------------------------------
  //  SIGN-UP
  // -----------------------------------------------------------------
  Future<User?> signUpWithDetails({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? location,
    String? farmSize,
    String? profileImageUrl,
  }) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      await user.updateDisplayName(fullName);
      await user.sendEmailVerification();

      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber ?? '',
        'location': location ?? '',
        'farmSize': farmSize ?? '',
        'profileImageUrl': profileImageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'scanCount': 0,
        'lastScan': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'crops': <String>[],
      });

      debugPrint('User registered: ${user.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-up error: ${e.message}');
      throw AuthException(e.message ?? 'Sign up failed');
    }
  }

  // -----------------------------------------------------------------
  //  SIGN-IN
  // -----------------------------------------------------------------
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      await user.reload();
      final refreshed = _firebaseAuth.currentUser;
      if (refreshed != null && !refreshed.emailVerified) {
        throw AuthException('Please verify your email before logging in.');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-in error: ${e.message}');
      throw AuthException(e.message ?? 'Sign in failed');
    }
  }

  // -----------------------------------------------------------------
  //  EMAIL VERIFICATION
  // -----------------------------------------------------------------
  Future<void> resendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.emailVerified) {
      throw AuthException('No verification needed or user not found.');
    }

    await user.sendEmailVerification();
    debugPrint('Verification email resent to ${user.email}');
  }

  // -----------------------------------------------------------------
  //  PASSWORD RESET
  // -----------------------------------------------------------------
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
    debugPrint('Password reset email sent to $email');
  }

  // -----------------------------------------------------------------
  //  PROFILE UPDATE
  // -----------------------------------------------------------------
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? location,
    String? farmSize,
    String? profileImageUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updateData = {};

    if (fullName != null) {
      await user.updateDisplayName(fullName);
      updateData['fullName'] = fullName;
    }
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (location != null) updateData['location'] = location;
    if (farmSize != null) updateData['farmSize'] = farmSize;
    if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

    updateData['lastUpdated'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(user.uid).update(updateData);
    debugPrint('Profile updated');
  }

  // Shortcut helpers
  Future<void> updatePhoneNumber(String v) => updateProfile(phoneNumber: v);
  Future<void> updateLocation(String v) => updateProfile(location: v);
  Future<void> updateFarmSize(String v) => updateProfile(farmSize: v);
  Future<void> updateProfileImage(String v) => updateProfile(profileImageUrl: v);
  Future<void> changeUsername(String v) => updateProfile(fullName: v);

  // -----------------------------------------------------------------
  //  USER DATA FETCH
  // -----------------------------------------------------------------
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = _firebaseAuth.currentUser?.uid;
    return uid != null ? getUserData(uid) : null;
  }

  // -----------------------------------------------------------------
  //  SCAN HISTORY
  // -----------------------------------------------------------------
  Future<void> saveScanResult({
    required String cropType,
    required Map<String, dynamic> scanData,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('scans')
        .add({
      'cropType': cropType,
      'scanData': scanData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(user.uid).update({
      'scanCount': FieldValue.increment(1),
      'lastScan': FieldValue.serverTimestamp(),
    });

    debugPrint('Scan saved');
  }

  Future<List<Map<String, dynamic>>> getScanHistory(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  // -----------------------------------------------------------------
  //  SIGN-OUT
  // -----------------------------------------------------------------
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // -----------------------------------------------------------------
  //  ACCOUNT DELETION
  // -----------------------------------------------------------------
  /// **Deletes the authenticated user** – Firestore data first, then Auth.
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No authenticated user to delete.');
    }

    final uid = user.uid;

    try {
      // 1. Clean Firestore
      await _deleteUserFirestoreData(uid);

      // 2. (Optional) Clean Storage – uncomment if you store a profile picture
      // await _deleteProfileImage(uid);

      // 3. Delete Auth record
      await user.delete();

      debugPrint('Account $uid deleted');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'For security you must log in again before deleting your account.',
        );
      }
      debugPrint('Auth delete error: ${e.message}');
      throw AuthException(e.message ?? 'Failed to delete account');
    } catch (e) {
      debugPrint('Unexpected delete error: $e');
      throw AuthException('Failed to delete account');
    }
  }

  // -----------------------------------------------------------------
  //  PRIVATE HELPERS – Firestore batch delete
  // -----------------------------------------------------------------
  Future<void> _deleteUserFirestoreData(String uid) async {
    var batch = _firestore.batch();
    int ops = 0;

    // root user doc
    batch.delete(_firestore.collection('users').doc(uid));
    ops++;

    // scans sub-collection
    final scansSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .get();

    for (final doc in scansSnap.docs) {
      batch.delete(doc.reference);
      ops++;

      if (ops >= 499) {
        await batch.commit();
        batch = _firestore.batch();
        ops = 0;
      }
    }

    if (ops > 0) await batch.commit();
  }

// -----------------------------------------------------------------
//  PRIVATE HELPERS – Storage (uncomment if you use it)
// -----------------------------------------------------------------
/*
  Future<void> _deleteProfileImage(String uid) async {
    final ref = FirebaseStorage.instance.ref().child('profileImages/$uid.jpg');
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
  */
}

// ---------------------------------------------------------------------
//  CUSTOM EXCEPTION
// ---------------------------------------------------------------------
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}