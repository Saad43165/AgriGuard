import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClearHistoryTile extends StatelessWidget {
  final VoidCallback? onHistoryCleared;
  final EdgeInsets? padding;

  const ClearHistoryTile({
    super.key,
    this.onHistoryCleared,
    this.padding,
  });

  Future<void> _clearScanHistory(BuildContext context) async {
    HapticFeedback.heavyImpact();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError(context, 'You must be logged in to clear history.');
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final scansRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans');

      final snapshot = await scansRef.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Also reset scan count
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'scanCount': 0,
        'lastScan': FieldValue.delete(),
      });

      await batch.commit();

      // Success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scan history cleared!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      onHistoryCleared?.call();
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to clear history: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          ),
          child: Icon(
            Icons.delete_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        title: Text(
          'Clear Scan History',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Remove all your previous scan records',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        onTap: () => _showConfirmationDialog(context),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Scan History?'),
        content: const Text(
          'This will permanently delete all your scan records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearScanHistory(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}