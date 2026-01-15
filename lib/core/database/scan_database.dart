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

    if (results.isNotEmpty) {
      return ScanModel.fromSqliteMap(results.first);
    }
    return null;
  }

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

  Future<void> deleteScan(String id) async {
    final db = await database;
    await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
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

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'scans',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<void> clearAllScans() async {
    final db = await database;
    await db.delete('scans');
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM scans');
    final columnsResult = await db.rawQuery('PRAGMA table_info(scans)');

    return {
      'scanCount': countResult.first['count'] as int,
      'columns': columnsResult.map((col) => col['name'] as String).toList(),
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}