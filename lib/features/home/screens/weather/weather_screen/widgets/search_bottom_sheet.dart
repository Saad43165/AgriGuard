import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../models/city_model.dart';
import '../../services/city_service.dart';

typedef SearchCallback = Future<void> Function(String city);

class SearchBottomSheet {
  const SearchBottomSheet._();

  static void show({
    required BuildContext context,
    required Color weatherColor,
    required SearchCallback onSearch,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54, // Simpler color
      builder: (context) => _SearchDialog(onSearch: onSearch),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final SearchCallback onSearch;

  const _SearchDialog({required this.onSearch});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final CitiesService _citiesService = CitiesService.instance;

  bool _isSearching = false;
  bool _isLoading = true;
  String? _error;

  static const Color _primaryColor = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);
    try {
      await _citiesService.loadCities();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load cities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String city) async {
    if (city.trim().isEmpty) {
      setState(() => _error = 'Please enter a city');
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      await widget.onSearch(city.trim());
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

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Search Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TypeAheadField<City>(
                        controller: _controller,
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            autofocus: true,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type city name...',
                              prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _primaryColor, width: 2),
                              ),
                              errorText: _error,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: _performSearch,
                          );
                        },
                        suggestionsCallback: (pattern) async {
                          return pattern.isEmpty
                              ? _citiesService.popularCities
                              : _citiesService.searchCities(pattern);
                        },
                        itemBuilder: (context, City city) {
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: _primaryColor,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              city.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              city.country,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              city.code,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                          );
                        },
                        onSelected: (City city) {
                          _controller.text = city.name;
                          _performSearch(city.name);
                        },
                        emptyBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No cities found'),
                        ),
                        decorationBuilder: (context, child) {
                          return Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                            child: child,
                          );
                        },
                        constraints: const BoxConstraints(maxHeight: 300),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isSearching
                              ? null
                              : () => _performSearch(_controller.text.trim()),
                          child: _isSearching
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Text(
                            'Search Weather',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}