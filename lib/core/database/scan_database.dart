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
      version: 6, // ✅ bumped from 5 to 6
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
        case 4:
          await _migrateV4ToV5(db);
          break;
        case 5:
          await _migrateV5ToV6(db);
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

  /// ✅ New migration: HuggingFace -> Roboflow
  Future<void> _migrateV4ToV5(Database db) async {
    print('📊 Migrating from v4 to v5 (analysisSource cleanup)');

    try {
      await db.rawUpdate('''
        UPDATE scans
        SET analysisSource = 'roboflow'
        WHERE LOWER(analysisSource) IN ('huggingface', 'hugging face', 'hf')
      ''');
      print('✅ Migrated old huggingface sources to roboflow');
    } catch (e) {
      print('⚠️ Error migrating analysisSource: $e');
    }
  }

  /// ✅ New migration: Roboflow -> PlantHealth
  Future<void> _migrateV5ToV6(Database db) async {
    print('📊 Migrating from v5 to v6 (analysisSource cleanup)');

    try {
      await db.rawUpdate('''
        UPDATE scans
        SET analysisSource = 'plantHealth'
        WHERE LOWER(analysisSource) IN ('roboflow')
      ''');
      print('✅ Migrated old roboflow sources to plantHealth');
    } catch (e) {
      print('⚠️ Error migrating analysisSource: $e');
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
      String columnType, [
        String? defaultValue,
      ]) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      final exists = columns.any((col) => col['name'] == columnName);

      if (!exists) {
        String sql;
        if (defaultValue != null) {
          sql =
          'ALTER TABLE $tableName ADD COLUMN $columnName $columnType DEFAULT $defaultValue';
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

  Future<ScanModel?> getScanById(String id) async {
    final db = await database;
    final results = await db.query(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) return ScanModel.fromSqliteMap(results.first);
    return null;
  }

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

  Future<void> deleteScan(String id) async {
    final db = await database;
    await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllScans() async {
    final db = await database;
    await db.delete('scans');
  }

  /// Ids of rows that still hold the photo as base64 text (pre-file storage).
  Future<List<String>> getIdsWithInlineImage(String userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT id FROM scans WHERE userId = ? AND imageBase64 IS NOT NULL AND imageBase64 != ''",
      [userId],
    );
    return rows.map((r) => r['id'].toString()).toList();
  }

  Future<void> setImageFile(String id, String path) async {
    final db = await database;
    await db.update(
      'scans',
      {'imagePath': path, 'imageBase64': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteScansForUser(String userId) async {
    final db = await database;
    return db.delete('scans', where: 'userId = ?', whereArgs: [userId]);
  }

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

  Future<int> getHealthyScansCount(String userId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count FROM scans 
      WHERE userId = ? 
      AND (LOWER(diseaseName) LIKE '%healthy%' OR diseaseName = '')
    ''', [userId]);

    return results.first['count'] as int;
  }

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

  Future<Map<String, int>> getDiseaseBreakdown(String userId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT diseaseName, COUNT(*) as count 
      FROM scans 
      WHERE userId = ? 
      GROUP BY diseaseName 
      ORDER BY count DESC
    ''', [userId]);

    final breakdown = <String, int>{};
    for (var row in results) {
      breakdown[row['diseaseName'] as String] = row['count'] as int;
    }
    return breakdown;
  }

  Future<Map<String, int>> getScansPerMonth(String userId, {int months = 6}) async {
    final db = await database;
    final cutoffDate =
    DateTime.now().subtract(Duration(days: months * 30)).toIso8601String();

    final results = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', scanDate) as month,
        COUNT(*) as count
      FROM scans
      WHERE userId = ? AND scanDate >= ?
      GROUP BY month
      ORDER BY month DESC
    ''', [userId, cutoffDate]);

    final monthlyData = <String, int>{};
    for (var row in results) {
      monthlyData[row['month'] as String] = row['count'] as int;
    }
    return monthlyData;
  }

  // ============================================
  // UTILITY OPERATIONS
  // ============================================

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

  Future<void> compactDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
    print('✅ Database compacted');
  }

  Future<List<Map<String, dynamic>>> exportAllScans(String userId) async {
    final db = await database;
    return db.query(
      'scans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scanDate DESC',
    );
  }

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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}