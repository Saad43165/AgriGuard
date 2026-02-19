import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/city_model.dart';

class CitiesService {
  static CitiesService? _instance;
  static CitiesService get instance => _instance ??= CitiesService._();

  CitiesService._();

  List<City>? _cities;
  bool _isLoaded = false;
  String? _errorMessage;

  Future<void> loadCities() async {
    if (_isLoaded && _cities != null && _cities!.isNotEmpty) {
      debugPrint('✅ Cities already loaded: ${_cities!.length}');
      return;
    }

    try {
      debugPrint('📂 Attempting to load cities from assets/data/cities.json...');

      final String response = await rootBundle.loadString('assets/data/cities.json');
      debugPrint('✅ JSON file loaded successfully, size: ${response.length} bytes');

      if (response.isEmpty) {
        throw Exception('JSON file is empty');
      }

      final dynamic jsonData = json.decode(response);
      debugPrint('✅ JSON decoded successfully');

      if (jsonData is! List) {
        throw Exception('JSON root is not a list, got: ${jsonData.runtimeType}');
      }

      final List<dynamic> data = jsonData;
      debugPrint('✅ Found ${data.length} cities in JSON');

      if (data.isEmpty) {
        throw Exception('Cities list is empty');
      }

      _cities = data.map((json) {
        try {
          return City.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ Error parsing city: $json - $e');
          return null;
        }
      }).whereType<City>().toList();

      _isLoaded = true;
      _errorMessage = null;

      debugPrint('✅ Cities service initialized successfully!');
      debugPrint('✅ Total cities loaded: ${_cities!.length}');
      debugPrint('✅ Sample city: ${_cities!.first.name}, ${_cities!.first.country}');

    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR loading cities: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _errorMessage = e.toString();
      _cities = [];
      _isLoaded = false;

      // Rethrow to show in UI
      rethrow;
    }
  }

  List<City> searchCities(String query) {
    if (_cities == null || _cities!.isEmpty) {
      debugPrint('⚠️ No cities loaded yet (cities: ${_cities?.length ?? 0})');
      return [];
    }

    if (query.isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase().trim();
    debugPrint('🔍 Searching for: "$lowerQuery" in ${_cities!.length} cities');

    final results = _cities!.where((city) {
      final matches = city.searchText.contains(lowerQuery);
      if (matches) {
        debugPrint('  ✓ Match: ${city.name}, ${city.country}');
      }
      return matches;
    }).take(10).toList();

    debugPrint('📋 Search results: ${results.length} cities found');
    return results;
  }

  List<City> get allCities {
    debugPrint('📋 Getting all cities: ${_cities?.length ?? 0}');
    return _cities ?? [];
  }

  List<City> get popularCities {
    if (_cities == null || _cities!.isEmpty) {
      debugPrint('⚠️ No cities for popular list (cities: ${_cities?.length ?? 0})');
      return [];
    }
    final popular = _cities!.take(20).toList();
    debugPrint('⭐ Returning ${popular.length} popular cities');
    return popular;
  }

  String? get error => _errorMessage;
  bool get isLoaded => _isLoaded;
}