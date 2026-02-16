import 'package:flutter/material.dart';

typedef SearchCallback = Future<void> Function(String city);

class SearchBottomSheet {
  const SearchBottomSheet._();

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
      ),
    );
  }
}

class _SearchSheetContent extends StatefulWidget {
  final TextEditingController controller;
  final Color weatherColor;
  final SearchCallback onSearch;

  const _SearchSheetContent({
    required this.controller,
    required this.weatherColor,
    required this.onSearch,
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
    if (city.trim().isEmpty) {
      setState(() => _error = 'Please enter a city name');
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      await widget.onSearch(city.trim());
      // Close the bottom sheet on success
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: _sheetDecoration(isDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(isDark: isDark),
            const SizedBox(height: 24),

            // Title with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.weatherColor,
                        widget.weatherColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.weatherColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Search Location',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search field
            TextField(
              controller: widget.controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
              decoration: _inputDecoration(isDark),
              onChanged: (_) => setState(() {}),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 20),

            // Search button
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
                  disabledBackgroundColor: widget.weatherColor.withOpacity(0.5),
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
                    SizedBox(width: 12),
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

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      hintText: 'Enter city name (e.g., London, Tokyo)',
      hintStyle: TextStyle(
        color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade500,
        fontSize: 15,
      ),
      prefixIcon: Icon(
        Icons.location_city_rounded,
        color: widget.weatherColor,
        size: 24,
      ),
      suffixIcon: widget.controller.text.isNotEmpty
          ? IconButton(
        icon: Icon(
          Icons.clear,
          color: isDark ? Colors.white70 : Colors.grey,
        ),
        onPressed: () {
          widget.controller.clear();
          setState(() {});
        },
      )
          : null,
      filled: true,
      fillColor: isDark
          ? widget.weatherColor.withOpacity(0.15)
          : widget.weatherColor.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: widget.weatherColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: widget.weatherColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
      errorText: _error,
      errorStyle: TextStyle(
        color: Colors.red.shade400,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  BoxDecoration _sheetDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
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

class _DragHandle extends StatelessWidget {
  final bool isDark;

  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}