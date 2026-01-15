import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/scan_database.dart';

class ClearHistoryTile extends StatefulWidget {
  final VoidCallback? onHistoryCleared;
  final EdgeInsets? padding;

  const ClearHistoryTile({
    super.key,
    this.onHistoryCleared,
    this.padding,
  });

  @override
  State<ClearHistoryTile> createState() => _ClearHistoryTileState();
}

class _ClearHistoryTileState extends State<ClearHistoryTile> {
  bool _isClearing = false;
  final ScanDatabase _scanDatabase = ScanDatabase.instance;

  Future<void> _clearScanHistory(BuildContext context) async {
    if (_isClearing) return;

    HapticFeedback.heavyImpact();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError(context, 'You must be logged in to clear history.');
      return;
    }

    setState(() => _isClearing = true);

    try {
      // 1. First, try to clear from all Firestore collections
      await _clearFirestoreScans(user.uid);

      // 2. Clear local SQLite database for this user
      await _clearLocalDatabase(user.uid);

      // 3. Clear shared preferences scan history
      await _clearSharedPreferences();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Scan history cleared successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      widget.onHistoryCleared?.call();
    } on FirebaseException catch (e) {
      if (context.mounted) {
        _showError(context, 'Firebase error: ${e.message}');
      }
      debugPrint('Firebase error clearing history: ${e.code} - ${e.message}');
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to clear history. Please try again.');
      }
      debugPrint('Error clearing history: $e');
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  // ADD THIS UPDATED METHOD HERE:
  Future<void> _clearFirestoreScans(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Clear from users/{userId}/scans subcollection
    try {
      final scansRef = firestore.collection('users').doc(userId).collection('scans');
      final snapshot = await scansRef.get();

      if (snapshot.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('✅ Cleared ${snapshot.docs.length} scans from users/scans');
      }
    } catch (e) {
      debugPrint('⚠️ Error clearing users/scans: $e');
      // Continue with other collections even if this fails
    }

    // Clear from onDeviceScans collection
    try {
      final onDeviceQuery = firestore
          .collection('onDeviceScans')
          .where('userId', isEqualTo: userId);
      final onDeviceSnapshot = await onDeviceQuery.get();

      if (onDeviceSnapshot.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final doc in onDeviceSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('✅ Cleared ${onDeviceSnapshot.docs.length} on-device scans');
      }
    } catch (e) {
      debugPrint('⚠️ Error clearing onDeviceScans: $e');
    }

    // Clear from advancedScans collection
    try {
      final advancedQuery = firestore
          .collection('advancedScans')
          .where('userId', isEqualTo: userId);
      final advancedSnapshot = await advancedQuery.get();

      if (advancedSnapshot.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final doc in advancedSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('✅ Cleared ${advancedSnapshot.docs.length} advanced scans');
      }
    } catch (e) {
      debugPrint('⚠️ Error clearing advancedScans: $e');
    }

    // CRITICAL: Update the user's scanCount to 0
    try {
      final userRef = firestore.collection('users').doc(userId);

      // Get local SQLite counts to verify
      final scanCounts = await _scanDatabase.getScanCounts(userId);
      final localTotal = scanCounts['total'] ?? 0;

      debugPrint('📊 Local SQLite scan count after deletion: $localTotal');

      // Update Firestore user document
      await userRef.update({
        'scanCount': 0,  // This will trigger the StreamBuilder to update
        'reportCount': FieldValue.delete(), // Optional: clear reports too
        'lastScan': FieldValue.delete(),
        'totalScans': 0,
        'onDeviceScans': 0,
        'advancedScans': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        // For debugging:
        'localScanCount': localTotal,
      });

      debugPrint('✅ Updated user document: scanCount set to 0');

      // Double check the update
      final updatedUser = await userRef.get();
      final updatedData = updatedUser.data() as Map<String, dynamic>?;
      debugPrint('✅ Verification - scanCount in Firestore: ${updatedData?['scanCount'] ?? 'N/A'}');
    } catch (e) {
      debugPrint('⚠️ Error updating user document: $e');
    }
  }

  Future<void> _clearLocalDatabase(String userId) async {
    try {
      debugPrint('🔄 Starting SQLite database clearing for user: $userId');

      // First, get all scans for this user
      final userScans = await _scanDatabase.getScansByUser(userId);
      debugPrint('📊 Found ${userScans.length} scans in SQLite for user: $userId');

      if (userScans.isEmpty) {
        debugPrint('✅ No scans found in SQLite for user: $userId');
        return;
      }

      // Option 1: Delete scans one by one (safer for multi-user apps)
      int deletedCount = 0;
      for (final scan in userScans) {
        if (scan.id != null) {
          try {
            await _scanDatabase.deleteScan(scan.id!);
            deletedCount++;
          } catch (e) {
            debugPrint('⚠️ Failed to delete scan ${scan.id}: $e');
          }
        }
      }

      debugPrint('✅ Deleted $deletedCount scans individually');

      // Verify deletion
      final remainingScans = await _scanDatabase.getScansByUser(userId);
      if (remainingScans.isEmpty) {
        debugPrint('✅ SQLite database successfully cleared for user: $userId');
      } else {
        debugPrint('⚠️ ${remainingScans.length} scans remain after individual deletion');

        // Option 2: Use the clearAllScans() method as last resort
        // WARNING: This clears ALL scans from ALL users!
        debugPrint('⚠️ Using clearAllScans() - will clear ALL users\' scans');
        await _scanDatabase.clearAllScans();
        debugPrint('✅ Used clearAllScans() - cleared entire SQLite database');
      }

    } catch (e) {
      debugPrint('❌ Error clearing local database: $e');
      // Try the nuclear option as fallback
      try {
        await _scanDatabase.clearAllScans();
        debugPrint('✅ Fallback: Used clearAllScans() after error');
      } catch (e2) {
        debugPrint('❌ Even clearAllScans() failed: $e2');
      }
    }
  }

  Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove any scan-related preferences
      await prefs.remove('last_scan_date');
      await prefs.remove('total_scans');
      await prefs.remove('recent_scans');
      await prefs.remove('scan_history_cache');
      await prefs.remove('last_sync_time');

      // Also clear any scan IDs
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains('scan_') || key.contains('Scan') || key.contains('SCAN')) {
          await prefs.remove(key);
        }
      }

      debugPrint('✅ Shared preferences cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing shared preferences: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    if (_isClearing) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade50,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.orange.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Clear All Scan History?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildBulletPoint('All scans from Firebase Cloud'),
                    _buildBulletPoint('All scans from local SQLite database'),
                    _buildBulletPoint('All scan history from device cache'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_isClearing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Clearing history...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearScanHistory(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showConfirmationDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.orange.shade50,
                ),
                child: _isClearing
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade700,
                  ),
                )
                    : Icon(
                  Icons.history_rounded,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isClearing ? 'Clearing History...' : 'Clear Scan History',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isClearing
                          ? 'Please wait while we clear all your scan data'
                          : 'Remove all scan data from cloud and device',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isClearing)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}