import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_model.dart';

class ScanDatabase {
  static final ScanDatabase instance = ScanDatabase._init();
  static Database? _database;

  ScanDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scans.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Migrating database from v$oldVersion to v$newVersion');

    for (int version = oldVersion; version < newVersion; version++) {
      switch (version) {
        case 1:
          await _migrateV1ToV2(db);
          break;
        case 2:
          await _migrateV2ToV3(db);
          break;
        case 3:
          await _migrateV3ToV4(db);
          break;
      }
    }
  }

  Future<void> _migrateV1ToV2(Database db) async {
    print('📊 Migrating from v1 to v2');

    await _safeAddColumn(
      db,
      'scans',
      'analysisSource',
      'TEXT',
      '"onDeviceML"',
    );

    await _safeAddColumn(
      db,
      'scans',
      'advancedData',
      'TEXT',
    );
  }

  Future<void> _migrateV2ToV3(Database db) async {
    print('📊 Migrating from v2 to v3');

    await _safeAddColumn(
      db,
      'scans',
      'scientificName',
      'TEXT',
    );

    await _safeAddColumn(
      db,
      'scans',
      'isAdvanced',
      'INTEGER',
      '0',
    );

    try {
      await db.rawUpdate('''
        UPDATE scans 
        SET isAdvanced = CASE 
          WHEN scanType = 'advanced' THEN 1 
          ELSE 0 
        END
      ''');
      print('✅ Updated isAdvanced values');
    } catch (e) {
      print('⚠️ Error updating isAdvanced: $e');
    }
  }

  Future<void> _migrateV3ToV4(Database db) async {
    print('📊 Migrating from v3 to v4');

    await _safeAddColumn(
      db,
      'scans',
      'createdAt',
      'TEXT',
    );

    try {
      await db.rawUpdate('''
        UPDATE scans 
        SET createdAt = scanDate 
        WHERE createdAt IS NULL OR createdAt = ''
      ''');
      print('✅ Set createdAt values from scanDate');
    } catch (e) {
      print('⚠️ Error setting createdAt: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        scanType TEXT NOT NULL,
        analysisSource TEXT NOT NULL,
        plantName TEXT NOT NULL,
        scientificName TEXT,
        diseaseName TEXT NOT NULL,
        severity TEXT NOT NULL,
        confidence INTEGER NOT NULL,
        symptoms TEXT,
        treatments TEXT,
        precautions TEXT,
        imagePath TEXT,
        imageUrl TEXT,
        imageBase64 TEXT,
        scanDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        rawData TEXT NOT NULL,
        advancedData TEXT,
        isSynced INTEGER DEFAULT 0,
        isAdvanced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_userId ON scans(userId)');
    await db.execute('CREATE INDEX idx_scanDate ON scans(scanDate)');
    await db.execute('CREATE INDEX idx_scanType ON scans(scanType)');
    await db.execute('CREATE INDEX idx_analysisSource ON scans(analysisSource)');
    await db.execute('CREATE INDEX idx_isSynced ON scans(isSynced)');
    await db.execute('CREATE INDEX idx_createdAt ON scans(createdAt)');
  }

  Future<void> _safeAddColumn(
      Database db,
      String tableName,
      String columnName,
      String columnType,
      [String? defaultValue]
      ) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      final exists = columns.any((col) => col['name'] == columnName);

      if (!exists) {
        String sql;
        if (defaultValue != null) {
          sql = 'ALTER TABLE $tableName ADD COLUMN $columnName $columnType DEFAULT $defaultValue';
        } else {
          sql = 'ALTER TABLE $tableName ADD COLUMN $columnName $columnType';
        }

        await db.execute(sql);
        print('✅ Added column $columnName to $tableName');
      } else {
        print('✅ Column $columnName already exists in $tableName');
      }
    } catch (e) {
      print('⚠️ Error adding column $columnName: $e');
      rethrow;
    }
  }

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  Future<String> createScan(ScanModel scan) async {
    final db = await database;

    final scanWithDefaults = scan.copyWith(
      id: scan.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final scanMap = scanWithDefaults.toSqliteMap();

    print('📊 Inserting scan with fields:');
    scanMap.forEach((key, value) {
      print('  $key: ${value.toString().length > 50 ? '...' : value}');
    });

    try {
      await db.insert(
        'scans',
        scanMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Scan saved successfully with ID: ${scanWithDefaults.id}');
      return scanWithDefaults.id!;
    } catch (e, stackTrace) {
      print('❌ Error saving scan: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get scans by user with optional limit
  Future<List<ScanModel>> getScansByUser(String userId, {int limit = 50}) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scanDate DESC',
      limit: limit,
    );

    return results.map((map) => ScanModel.fromSqliteMap(map)).toList();
  }

  /// Get ALL scans for a user (no limit) - returns raw maps
  Future<List<Map<String, dynamic>>> getAllScans(String userId) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scanDate DESC',
    );

    return results;
  }

  /// Get ALL scans for a user as ScanModel objects
  Future<List<ScanModel>> getAllScanModels(String userId) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scanDate DESC',
    );

    return results.map((map) => ScanModel.fromSqliteMap(map)).toList();
  }

  /// Get on-device scans only
  Future<List<ScanModel>> getOnDeviceScans(String userId) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ? AND scanType = ?',
      whereArgs: [userId, ScanType.onDevice.name],
      orderBy: 'scanDate DESC',
    );

    return results.map((map) => ScanModel.fromSqliteMap(map)).toList();
  }

  /// Get advanced scans only
  Future<List<ScanModel>> getAdvancedScans(String userId) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ? AND scanType = ?',
      whereArgs: [userId, ScanType.advanced.name],
      orderBy: 'scanDate DESC',
    );

    return results.map((map) => ScanModel.fromSqliteMap(map)).toList();
  }

  /// Get scans by analysis source (onDeviceML, groq, plantid)
  Future<List<ScanModel>> getScansBySource(String userId, String source) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ? AND analysisSource = ?',
      whereArgs: [userId, source],
      orderBy: 'scanDate DESC',
    );

    return results.map((map) => ScanModel.fromSqliteMap(map)).toList();
  }

  /// Get a single scan by ID
  Future<ScanModel?> getScanById(String id) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return ScanModel.fromSqliteMap(results.first);
    }
    return null;
  }

  /// Get unsynced scans
  Future<List<ScanModel>> getUnsyncedScans(String userId) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ? AND isSynced = ?',
      whereArgs: [userId, 0],
      orderBy: 'scanDate DESC',
    );

    return results.map((map) => ScanModel.fromSqliteMap(map)).toList();
  }

  /// Get recent scans (last N days)
  Future<List<ScanModel>> getRecentScans(String userId, {int days = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    final results = await db.query(
      'scans',
      where: 'userId = ? AND scanDate >= ?',
      whereArgs: [userId, cutoffDate],
      orderBy: 'scanDate DESC',
    );

    return results.map((map) => ScanModel.fromSqliteMap(map)).toList();
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update an existing scan
  Future<void> updateScan(ScanModel scan) async {
    if (scan.id == null) {
      throw Exception('Cannot update scan without ID');
    }

    final db = await database;
    await db.update(
      'scans',
      scan.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [scan.id],
    );
  }

  /// Mark a scan as synced
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'scans',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  /// Delete a single scan
  Future<void> deleteScan(String id) async {
    final db = await database;
    await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all scans
  Future<void> clearAllScans() async {
    final db = await database;
    await db.delete('scans');
  }

  /// Delete scans older than N days
  Future<int> deleteOldScans(String userId, {int days = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    return await db.delete(
      'scans',
      where: 'userId = ? AND scanDate < ?',
      whereArgs: [userId, cutoffDate],
    );
  }

  // ============================================
  // STATISTICS & COUNTS
  // ============================================

  /// Get basic scan counts
  Future<Map<String, int>> getScanCounts(String userId) async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE userId = ?',
      [userId],
    );

    final onDeviceResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE userId = ? AND scanType = ?',
      [userId, ScanType.onDevice.name],
    );

    final advancedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE userId = ? AND scanType = ?',
      [userId, ScanType.advanced.name],
    );

    return {
      'total': totalResult.first['count'] as int,
      'onDevice': onDeviceResult.first['count'] as int,
      'advanced': advancedResult.first['count'] as int,
    };
  }

  /// Get healthy scans count
  Future<int> getHealthyScansCount(String userId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count FROM scans 
      WHERE userId = ? 
      AND (LOWER(diseaseName) LIKE '%healthy%' OR diseaseName = '')
    ''', [userId]);

    return results.first['count'] as int;
  }

  /// Get diseased scans count
  Future<int> getDiseasedScansCount(String userId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count FROM scans 
      WHERE userId = ? 
      AND LOWER(diseaseName) NOT LIKE '%healthy%' 
      AND diseaseName != ''
    ''', [userId]);

    return results.first['count'] as int;
  }

  /// Get detailed statistics (all-in-one)
  Future<Map<String, int>> getDetailedStats(String userId) async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE userId = ?',
      [userId],
    );

    final healthyResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM scans 
      WHERE userId = ? 
      AND (LOWER(diseaseName) LIKE '%healthy%' OR diseaseName = '')
    ''', [userId]);

    final diseasedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM scans 
      WHERE userId = ? 
      AND LOWER(diseaseName) NOT LIKE '%healthy%' 
      AND diseaseName != ''
    ''', [userId]);

    final onDeviceResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE userId = ? AND scanType = ?',
      [userId, ScanType.onDevice.name],
    );

    final advancedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE userId = ? AND scanType = ?',
      [userId, ScanType.advanced.name],
    );

    final unsyncedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE userId = ? AND isSynced = 0',
      [userId],
    );

    return {
      'total': totalResult.first['count'] as int,
      'healthy': healthyResult.first['count'] as int,
      'diseased': diseasedResult.first['count'] as int,
      'onDevice': onDeviceResult.first['count'] as int,
      'advanced': advancedResult.first['count'] as int,
      'unsynced': unsyncedResult.first['count'] as int,
    };
  }

  /// Get scans grouped by disease
  Future<Map<String, int>> getDiseaseBreakdown(String userId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT diseaseName, COUNT(*) as count 
      FROM scans 
      WHERE userId = ? 
      GROUP BY diseaseName 
      ORDER BY count DESC
    ''', [userId]);

    Map<String, int> breakdown = {};
    for (var row in results) {
      final disease = row['diseaseName'] as String;
      final count = row['count'] as int;
      breakdown[disease] = count;
    }

    return breakdown;
  }

  /// Get scans per month for charts
  Future<Map<String, int>> getScansPerMonth(String userId, {int months = 6}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: months * 30)).toIso8601String();

    final results = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', scanDate) as month,
        COUNT(*) as count
      FROM scans
      WHERE userId = ? AND scanDate >= ?
      GROUP BY month
      ORDER BY month DESC
    ''', [userId, cutoffDate]);

    Map<String, int> monthlyData = {};
    for (var row in results) {
      final month = row['month'] as String;
      final count = row['count'] as int;
      monthlyData[month] = count;
    }

    return monthlyData;
  }

  // ============================================
  // UTILITY OPERATIONS
  // ============================================

  /// Get database information
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM scans');
    final columnsResult = await db.rawQuery('PRAGMA table_info(scans)');
    final indexResult = await db.rawQuery('PRAGMA index_list(scans)');

    return {
      'scanCount': countResult.first['count'] as int,
      'columns': columnsResult.map((col) => col['name'] as String).toList(),
      'indexes': indexResult.map((idx) => idx['name'] as String).toList(),
      'version': (await db.getVersion()),
    };
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scans.db');

    try {
      final file = await File(path).stat();
      return file.size;
    } catch (e) {
      print('⚠️ Error getting database size: $e');
      return 0;
    }
  }

  /// Compact/vacuum database
  Future<void> compactDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
    print('✅ Database compacted');
  }

  /// Export all scans for backup
  Future<List<Map<String, dynamic>>> exportAllScans(String userId) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scanDate DESC',
    );

    return results;
  }

  /// Import scans from backup
  Future<int> importScans(List<Map<String, dynamic>> scans) async {
    final db = await database;
    int imported = 0;

    for (var scanMap in scans) {
      try {
        await db.insert(
          'scans',
          scanMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        imported++;
      } catch (e) {
        print('⚠️ Error importing scan: $e');
      }
    }

    print('✅ Imported $imported scans');
    return imported;
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}