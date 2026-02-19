import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../models/city_model.dart';
import '../../provider/weather_provider.dart';
import '../../services/city_service.dart';

class CitySearchDialog {
  static void show(
      BuildContext context,
      WeatherProvider provider,
      Color weatherColor,
      ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _CitySearchDialog(
        provider: provider,
      ),
    );
  }
}

class _CitySearchDialog extends StatefulWidget {
  final WeatherProvider provider;

  const _CitySearchDialog({
    required this.provider,
  });

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final CitiesService _citiesService = CitiesService.instance;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  bool _isSearching = false;
  bool _isLoading = true;
  String? _error;

  // Fixed colors - same as search_bottom_sheet.dart
  static const Color _primaryColor = Color(0xFF6366F1); // Indigo
  static const Color _secondaryColor = Color(0xFF8B5CF6); // Purple

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);

    try {
      await _citiesService.loadCities();
      debugPrint('✅ Cities loaded in card: ${_citiesService.allCities.length}');

      if (_citiesService.allCities.isEmpty) {
        throw Exception('No cities loaded - check assets/data/cities.json');
      }
    } catch (e) {
      debugPrint('❌ Error in card loading cities: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load cities: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String cityName) async {
    if (cityName.trim().isEmpty) {
      setState(() => _error = 'Please enter or select a city');
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      await widget.provider.loadWeatherForCity(cityName.trim());
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

    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  const Color(0xFF2D2D2D),
                  const Color(0xFF252525),
                ]
                    : [
                  Colors.white,
                  const Color(0xFFF8F9FF),
                ],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.08),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryColor.withOpacity(0.15),
                        _secondaryColor.withOpacity(0.1),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.08),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryColor, _secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.4),
                              blurRadius: 12,
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
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_primaryColor, _secondaryColor],
                          ).createShader(bounds),
                          child: const Text(
                            'Search Location',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.25)
                                : Colors.black.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content area
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field
                        _isLoading
                            ? Container(
                          padding:
                          const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading cities...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )
                            : TypeAheadField<City>(
                          controller: _searchController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: true,
                              textCapitalization:
                              TextCapitalization.words,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type city name...',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: const Icon(
                                  Icons.location_city_rounded,
                                  color: _primaryColor,
                                  size: 24,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _error = null);
                                  },
                                )
                                    : null,
                                filled: true,
                                fillColor: isDark
                                    ? _primaryColor.withOpacity(0.15)
                                    : _primaryColor.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? _primaryColor.withOpacity(0.4)
                                        : _primaryColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: _primaryColor,
                                    width: 2.5,
                                  ),
                                ),
                                errorText: _error,
                                errorStyle: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              onSubmitted: _performSearch,
                            );
                          },
                          suggestionsCallback: (pattern) async {
                            List<City> results;
                            if (pattern.isEmpty) {
                              results = _citiesService.popularCities;
                            } else {
                              results =
                                  _citiesService.searchCities(pattern);
                            }
                            return results;
                          },
                          itemBuilder: (context, City city) {
                            return Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.03)
                                    : Colors.black.withOpacity(0.02),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  city.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                subtitle: Text(
                                  city.country,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.black54,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _primaryColor.withOpacity(0.3),
                                        _secondaryColor.withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    city.code,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: _primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          onSelected: (City city) {
                            _searchController.text = city.name;
                            _performSearch(city.name);
                          },
                          emptyBuilder: (context) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ]
                                          : [
                                        Colors.black.withOpacity(0.05),
                                        Colors.black.withOpacity(0.03),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.black38,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No cities found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          loadingBuilder: (context) => const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                                ),
                              ),
                            ),
                          ),
                          decorationBuilder: (context, child) {
                            return Material(
                              elevation: 12,
                              borderRadius: BorderRadius.circular(20),
                              color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                              shadowColor: _primaryColor.withOpacity(0.3),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.15)
                                        : _primaryColor.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          constraints: const BoxConstraints(
                            maxHeight: 350,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Search Button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                                disabledBackgroundColor:
                                _primaryColor.withOpacity(0.5),
                              ),
                              onPressed: _isSearching
                                  ? null
                                  : () => _performSearch(
                                  _searchController.text.trim()),
                              child: _isSearching
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                                  : const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_rounded, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'Search Weather',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}