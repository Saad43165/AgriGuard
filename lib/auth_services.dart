import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter for current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream to listen for authentication state changes
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  // Sign up with email, password, and extra details
  Future<User?> signUpWithDetails({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? location,
    String? farmSize,
    String? profileImageUrl, // ADDED: Profile image support
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Update displayName
        await user.updateDisplayName(fullName);
        // Send email verification
        await user.sendEmailVerification();
        // Save extra details in Firestore
        await _firestore.collection("users").doc(user.uid).set({
          "fullName": fullName,
          "email": email,
          "phoneNumber": phoneNumber ?? "",
          "location": location ?? "",
          "farmSize": farmSize ?? "",
          "profileImageUrl": profileImageUrl ?? "", // ADDED: Profile image
          "createdAt": DateTime.now(),
          "emailVerified": false, // Track verification status
          "scanCount": 0, // ADDED: Initialize scan count
          "lastUpdated": DateTime.now(), // ADDED: Last updated timestamp
        });

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print("Error during sign up: ${e.message}");
      throw AuthException(e.message ?? "Sign up failed");
    }
  }

  // Login with email + password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null && !user.emailVerified) {
        throw AuthException("Please verify your email before logging in.");
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("Error during sign in: ${e.message}");
      throw AuthException(e.message ?? "Sign in failed");
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print("Password reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      print("Error during password reset: ${e.message}");
      throw AuthException(e.message ?? "Password reset failed");
    }
  }

  // Update user profile information (COMPREHENSIVE UPDATE)
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? location,
    String? farmSize,
    String? profileImageUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final updateData = <String, dynamic>{};

        // Update Firebase Auth display name if fullName is provided
        if (fullName != null) {
          await user.updateDisplayName(fullName);
          updateData['fullName'] = fullName;
        }

        // Update other fields in Firestore
        if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
        if (location != null) updateData['location'] = location;
        if (farmSize != null) updateData['farmSize'] = farmSize;
        if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

        // Always update the lastUpdated timestamp
        updateData['lastUpdated'] = DateTime.now();

        // Update Firestore document
        await _firestore.collection("users").doc(user.uid).update(updateData);
        print("Profile updated successfully");
      }
    } catch (e) {
      print("Error updating profile: $e");
      throw AuthException("Failed to update profile");
    }
  }

  // Update specific fields individually
  Future<void> updatePhoneNumber(String phoneNumber) async {
    await updateProfile(phoneNumber: phoneNumber);
  }

  Future<void> updateLocation(String location) async {
    await updateProfile(location: location);
  }

  Future<void> updateFarmSize(String farmSize) async {
    await updateProfile(farmSize: farmSize);
  }

  Future<void> updateProfileImage(String profileImageUrl) async {
    await updateProfile(profileImageUrl: profileImageUrl);
  }

  // Change current user's username (updated to use the new updateProfile method)
  Future<void> changeUsername(String newUsername) async {
    try {
      await updateProfile(fullName: newUsername);
      print("Username updated to $newUsername");
    } catch (e) {
      print("Error updating username: $e");
      throw AuthException("Failed to update username");
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _firestore.collection("users").doc(uid).get();
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      throw AuthException("Failed to get user data");
    }
  }

  // Save scan results to user's history
  Future<void> saveScanResult({
    required String cropType,
    required Map<String, dynamic> scanData,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Save scan to user's scan history subcollection
        await _firestore
            .collection("users")
            .doc(user.uid)
            .collection("scans")
            .add({
          'cropType': cropType,
          'scanData': scanData,
          'timestamp': DateTime.now(),
        });

        // Update user's scan count
        await _firestore.collection("users").doc(user.uid).update({
          'scanCount': FieldValue.increment(1),
          'lastScan': DateTime.now(),
        });

        print("Scan result saved successfully");
      }
    } catch (e) {
      print("Error saving scan result: $e");
      throw AuthException("Failed to save scan result");
    }
  }

  // Get user's scan history
  Future<List<Map<String, dynamic>>> getScanHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .doc(uid)
          .collection("scans")
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error getting scan history: $e");
      throw AuthException("Failed to get scan history");
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Error during sign out: $e");
      throw AuthException("Sign out failed");
    }
  }
}

// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}