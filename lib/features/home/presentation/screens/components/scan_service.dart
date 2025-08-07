import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanService {
  Future<List<Map<String, dynamic>>> fetchRecentScans() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];

    List<Map<String, dynamic>> scans = [];
    for (String scanJson in scansJson) {
      try {
        final Map<String, dynamic> scan = Map<String, dynamic>.from(
          jsonDecode(scanJson) as Map,
        );
        scans.add(scan);
      } catch (e) {
        debugPrint('Error parsing ResultScreen: $e');
      }
    }
    return scans;
  }

  Future<void> saveScan(Map<String, dynamic> scan) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];

    scansJson.insert(0, jsonEncode(scan));

    if (scansJson.length > 10) {
      scansJson.removeRange(10, scansJson.length);
    }

    await prefs.setStringList('recent_scans', scansJson);
  }

  Future<void> deleteScan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];
    final updatedScans = scansJson.where((json) {
      final scan = jsonDecode(json) as Map<String, dynamic>;
      return scan['id'] != id;
    }).toList();
    await prefs.setStringList('recent_scans', updatedScans);
  }

  Future<void> clearScans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_scans');
  }
}