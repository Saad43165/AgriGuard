import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/weather_provider.dart';

typedef SearchCallback = Future<void> Function(String city);

class SearchBottomSheet {
  const SearchBottomSheet._(); // Private constructor

  /// Shows the search bottom sheet
  static void show({
    required BuildContext context,
    required Color weatherColor,
    required SearchCallback onSearch,
  }) {
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => _SearchSheetContent(
        controller: controller,
        weatherColor: weatherColor,
        onSearch: onSearch,
        modalContext: modalContext,
      ),
    );
  }
}

/// Private StatefulWidget to manage local state (isSearching, error)
class _SearchSheetContent extends StatefulWidget {
  final TextEditingController controller;
  final Color weatherColor;
  final SearchCallback onSearch;
  final BuildContext modalContext;

  const _SearchSheetContent({
    required this.controller,
    required this.weatherColor,
    required this.onSearch,
    required this.modalContext,
  });

  @override
  State<_SearchSheetContent> createState() => _SearchSheetContentState();
}

class _SearchSheetContentState extends State<_SearchSheetContent> {
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String city) async {
    if (city.isEmpty) {
      setState(() => _error = 'Please enter a city name');
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      await widget.onSearch(city);
      if (widget.modalContext.mounted) {
        Navigator.pop(widget.modalContext);
      }
    } catch (e) {
      setState(() {
        _error = 'City not found. Please try again.';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: _sheetDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            const SizedBox(height: 24),
            Text(
              'Search Location',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: _inputDecoration(
                weatherColor: widget.weatherColor,
                error: _error,
                controller: widget.controller,
                onClear: () => setState(() => widget.controller.clear()),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.weatherColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSearching
                    ? null
                    : () => _performSearch(widget.controller.text.trim()),
                child: _isSearching
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Search Weather',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helper: Input decoration
  // -------------------------------------------------------------------------
  InputDecoration _inputDecoration({
    required Color weatherColor,
    required String? error,
    required TextEditingController controller,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: 'Enter city name (e.g., London, Tokyo)',
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      prefixIcon: Icon(Icons.search_rounded, color: weatherColor, size: 24),
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
        icon: const Icon(Icons.clear),
        onPressed: onClear,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      )
          : null,
      filled: true,
      fillColor: weatherColor.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: weatherColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      errorText: error,
      errorStyle: TextStyle(color: Colors.red.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // -------------------------------------------------------------------------
  // Helper: Sheet background
  // -------------------------------------------------------------------------
  BoxDecoration _sheetDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------------
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}