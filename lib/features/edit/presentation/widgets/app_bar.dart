import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class EditAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentHistoryIndex;
  final int historyLength;
  final bool isProcessing;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const EditAppBar({
    super.key,
    required this.currentHistoryIndex,
    required this.historyLength,
    required this.isProcessing,
    required this.onUndo,
    required this.onRedo,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.3),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppStrings.editImage,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo_rounded,
            color: currentHistoryIndex > 0 ? Colors.white : Colors.white54,
          ),
          onPressed: currentHistoryIndex > 0 ? onUndo : null,
          tooltip: AppStrings.undo,
        ),
        IconButton(
          icon: Icon(
            Icons.redo_rounded,
            color: currentHistoryIndex < historyLength - 1 ? Colors.white : Colors.white54,
          ),
          onPressed: currentHistoryIndex < historyLength - 1 ? onRedo : null,
          tooltip: AppStrings.redo,
        ),
        IconButton(
          icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
          onPressed: onReset,
          tooltip: AppStrings.reset,
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: isProcessing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check_rounded, color: Colors.white),
            onPressed: isProcessing ? null : onSave,
            tooltip: AppStrings.save,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}