import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Global notifier – keep if used elsewhere
ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------------------------------------------------
  //  GETTERS
  // -----------------------------------------------------------------
  User? get currentUser => _auth.currentUser;
  Stream<User?> get user => _auth.authStateChanges();

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
    _validateEmail(email);
    _validatePassword(password);
    _validateName(fullName);

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = result.user!;
      await user.updateDisplayName(fullName);
      await user.sendEmailVerification();

      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'email': email.trim(),
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
      }, SetOptions(merge: true));

      debugPrint('User registered: ${user.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e, isSignUp: true);
    }
  }

  // -----------------------------------------------------------------
  //  SIGN-IN
  // -----------------------------------------------------------------
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    _validateEmail(email);
    _validatePassword(password);

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = result.user!;
      await user.reload();

      if (!user.emailVerified) {
        throw AuthException('Please verify your email before logging in.');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // -----------------------------------------------------------------
  //  EMAIL VERIFICATION
  // -----------------------------------------------------------------
  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No user logged in.');
    if (user.emailVerified) throw AuthException('Email already verified.');

    await user.sendEmailVerification();
    debugPrint('Verification email resent to ${user.email}');
  }

  // -----------------------------------------------------------------
  //  PASSWORD RESET
  // -----------------------------------------------------------------
  Future<void> resetPassword(String email) async {
    _validateEmail(email);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
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
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No user logged in.');

    final updateData = <String, dynamic>{};
    if (fullName != null) {
      await user.updateDisplayName(fullName);
      updateData['fullName'] = fullName;
    }
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (location != null) updateData['location'] = location;
    if (farmSize != null) updateData['farmSize'] = farmSize;
    if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

    if (updateData.isNotEmpty) {
      updateData['lastUpdated'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
    }
  }

  // Shortcuts
  Future<void> updatePhoneNumber(String v) => updateProfile(phoneNumber: v);
  Future<void> updateLocation(String v) => updateProfile(location: v);
  Future<void> updateFarmSize(String v) => updateProfile(farmSize: v);
  Future<void> updateProfileImage(String v) => updateProfile(profileImageUrl: v);
  Future<void> changeUsername(String v) => updateProfile(fullName: v);

  // -----------------------------------------------------------------
  //  USER DATA
  // -----------------------------------------------------------------
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = _auth.currentUser?.uid;
    return uid != null ? getUserData(uid) : null;
  }

  // -----------------------------------------------------------------
  //  SCAN HISTORY
  // -----------------------------------------------------------------
  Future<void> saveScanResult({
    required String cropType,
    required Map<String, dynamic> scanData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No user logged in.');

    final scanRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('scans')
        .doc();

    await _firestore.runTransaction((tx) async {
      tx.set(scanRef, {
        'cropType': cropType,
        'scanData': scanData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      tx.set(
        _firestore.collection('users').doc(user.uid),
        {
          'scanCount': FieldValue.increment(1),
          'lastScan': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
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
    await _auth.signOut();
  }

  // -----------------------------------------------------------------
  //  SOCIAL SIGN-IN (GOOGLE)
  // -----------------------------------------------------------------
  Future<User?> signInWithGoogle() async {
    try {
      // Force account picker instead of silently reusing the last account.
      // This prevents "auto login" after a user signs out and taps Google again.
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.disconnect();
      } catch (_) {
        // If not previously signed in / disconnect fails, ignore.
        try {
          await googleSignIn.signOut();
        } catch (_) {}
      }

      final account = await googleSignIn.signIn();
      if (account == null) return null; // user cancelled

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return null;

      await _upsertUserProfileFromAuth(user, provider: 'google');
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  Future<void> _upsertUserProfileFromAuth(User user, {required String provider}) async {
    final displayName = user.displayName ?? '';
    final email = user.email ?? '';
    await _firestore.collection('users').doc(user.uid).set({
      'fullName': displayName,
      'email': email,
      'profileImageUrl': user.photoURL ?? '',
      'lastUpdated': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'emailVerified': user.emailVerified,
      'authProvider': provider,
      'scanCount': FieldValue.increment(0),
      'crops': <String>[],
    }, SetOptions(merge: true));
  }

  // -----------------------------------------------------------------
  //  ACCOUNT DELETION
  // -----------------------------------------------------------------
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No user is currently logged in.');

    try {
      await _deleteUserFirestoreData(user.uid);
      await user.delete();
      debugPrint('Account ${user.uid} deleted');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'For security, please log in again before deleting your account.',
        );
      }
      throw _mapAuthError(e);
    } catch (e) {
      throw AuthException('Failed to delete account. Try again.');
    }
  }

  // -----------------------------------------------------------------
  //  PRIVATE: DELETE USER DATA
  // -----------------------------------------------------------------
  Future<void> _deleteUserFirestoreData(String uid) async {
    final batch = _firestore.batch();
    var ops = 0;

    // Delete root user doc
    batch.delete(_firestore.collection('users').doc(uid));
    ops++;

    // Delete scans
    final scans = await _firestore.collection('users').doc(uid).collection('scans').get();
    for (final doc in scans.docs) {
      batch.delete(doc.reference);
      ops++;
      if (ops >= 499) {
        await batch.commit();
        ops = 0;
      }
    }

    if (ops > 0) await batch.commit();
  }

  // -----------------------------------------------------------------
  //  VALIDATION
  // -----------------------------------------------------------------
  void _validateEmail(String email) {
    if (email.trim().isEmpty) throw AuthException('Email is required.');
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email.trim())) {
      throw AuthException('Enter a valid email address.');
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) throw AuthException('Password is required.');
    if (password.length < 6) throw AuthException('Password must be at least 6 characters.');
  }

  void _validateName(String name) {
    if (name.trim().isEmpty) throw AuthException('Full name is required.');
  }

  // -----------------------------------------------------------------
  //  ERROR MAPPING
  // -----------------------------------------------------------------
  AuthException _mapAuthError(FirebaseAuthException e, {bool isSignUp = false}) {
    switch (e.code) {
      case 'email-already-in-use':
        return AuthException('An account with this email already exists.');
      case 'invalid-email':
        return AuthException('Please enter a valid email address.');
      case 'weak-password':
        return AuthException('Password is too weak. Use at least 6 characters.');
      case 'user-not-found':
        return AuthException('No account found with this email.');
      case 'wrong-password':
        return AuthException('Incorrect password. Please try again.');
      case 'invalid-credential':
        return AuthException('Invalid email or password.');
      case 'user-disabled':
        return AuthException('This account has been disabled.');
      case 'too-many-requests':
        return AuthException('Too many attempts. Please try again later.');
      case 'operation-not-allowed':
        return AuthException('Email/password sign-in is disabled.');
      case 'network-request-failed':
        return AuthException('No internet connection.');
      case 'requires-recent-login':
        return AuthException('Please log in again to continue.');
      default:
        return AuthException(isSignUp
            ? 'Sign up failed. Please try again.'
            : 'Login failed. Please try again.');
    }
  }
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