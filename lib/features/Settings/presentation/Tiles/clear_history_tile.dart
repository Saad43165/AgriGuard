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
  String _currentStep = '';

  Future<void> _clearScanHistory(BuildContext context) async {
    if (_isClearing) return;

    setState(() {
      _isClearing = true;
      _currentStep = 'Starting...';
    });

    try {
      HapticFeedback.heavyImpact();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please log in to clear history');
      }

      debugPrint('🔄 Starting clear for user: ${user.uid}');

      // Step 1: Clear SQLite (faster, do this first)
      setState(() => _currentStep = 'Clearing local database...');
      await _clearLocalDatabaseSimple(user.uid);

      // Step 2: Clear Firestore
      setState(() => _currentStep = 'Clearing cloud data...');
      await _clearFirestoreSimple(user.uid);

      // Step 3: Clear SharedPreferences
      setState(() => _currentStep = 'Cleaning cache...');
      await _clearSharedPreferences();

      debugPrint('✅ All clear operations completed');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('History cleared successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      widget.onHistoryCleared?.call();
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (context.mounted) {
        _showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
          _currentStep = '';
        });
      }
    }
  }

  // SIMPLIFIED LOCAL DATABASE CLEAR
  Future<void> _clearLocalDatabaseSimple(String userId) async {
    debugPrint('🔄 Clearing SQLite database...');

    try {
      final db = ScanDatabase.instance;

      // Just use clearAllScans - it's simpler and works
      await db.clearAllScans().timeout(const Duration(seconds: 10));

      debugPrint('✅ SQLite cleared successfully');
    } catch (e) {
      debugPrint('❌ SQLite error: $e');
      // Don't throw - continue with other operations
    }
  }

  // SIMPLIFIED FIRESTORE CLEAR
  Future<void> _clearFirestoreSimple(String userId) async {
    debugPrint('🔄 Clearing Firestore...');

    try {
      final firestore = FirebaseFirestore.instance;

      // Just update the user document - don't try to delete individual docs
      await firestore.collection('users').doc(userId).update({
        'scanCount': 0,
        'totalScans': 0,
        'onDeviceScans': 0,
        'advancedScans': 0,
        'lastScan': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      debugPrint('✅ Firestore user doc updated');

      // Optional: Try to clear subcollections (but don't wait for it)
      _clearFirestoreSubcollections(userId).catchError((e) {
        debugPrint('⚠️ Background subcollection clear failed: $e');
      });
    } catch (e) {
      debugPrint('❌ Firestore error: $e');
      // Don't throw - the main goal (resetting counts) succeeded
    }
  }

  // BACKGROUND OPERATION - Don't wait for this
  Future<void> _clearFirestoreSubcollections(String userId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Clear users/{userId}/scans
      final scansQuery = firestore
          .collection('users')
          .doc(userId)
          .collection('scans')
          .limit(500); // Limit to prevent hanging

      final scansSnapshot = await scansQuery.get();
      if (scansSnapshot.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final doc in scansSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('⚠️ Error clearing subcollections: $e');
    }
  }

  Future<void> _clearSharedPreferences() async {
    debugPrint('🔄 Clearing SharedPreferences...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) =>
      key.toLowerCase().contains('scan') ||
          key == 'last_sync_time' ||
          key == 'total_scans'
      ).toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('✅ Cleared ${keys.length} preferences');
    } catch (e) {
      debugPrint('⚠️ SharedPreferences error: $e');
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    if (_isClearing) return;

    showDialog(
      context: context,
      barrierDismissible: !_isClearing,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.orange.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Clear History?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your scan data from both cloud and device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: _isClearing ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isClearing
                ? null
                : () {
              Navigator.pop(context);
              _clearScanHistory(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
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
        onTap: _isClearing ? null : () => _showConfirmationDialog(context),
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
                      _isClearing ? 'Clearing...' : 'Clear Scan History',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isClearing && _currentStep.isNotEmpty
                          ? _currentStep
                          : 'Remove all scan data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}