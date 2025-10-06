import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

import '../models/sms_message.dart';
import '../models/classification_result.dart';
import '../models/spam_keyword.dart';
import '../models/app_config.dart';

/// Database service for storing SMS data, classifications, and keywords
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final Logger _logger = Logger();
  Database? _database;

  static const String _databaseName = 'sms_spam_detector.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _smsTable = 'sms_messages';
  static const String _classificationsTable = 'classifications';
  static const String _keywordsTable = 'spam_keywords';
  static const String _configTable = 'app_config';
  static const String _statsTable = 'statistics';

  /// Initialize the database
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing database...');

      // Check if we're running on web platform
      if (kIsWeb) {
        _logger.w('Running on web platform - using in-memory storage');
        return _initializeWebStorage();
      }

      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      _logger.i('Database initialized successfully at: $path');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize database',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // In-memory storage for web platform
  final List<SmsMessage> _webSmsMessages = [];
  final List<ClassificationResult> _webClassifications = [];
  final List<SpamKeyword> _webKeywords = [];
  AppConfig? _webConfig;

  Future<bool> _initializeWebStorage() async {
    _logger.i('Initializing web storage with sample data...');

    final now = DateTime.now();

    // Add some default spam keywords for testing
    _webKeywords.addAll([
      SpamKeyword(
        id: 'default_1',
        keyword: 'free',
        weight: 0.8,
        frequency: 5,
        firstSeen: now,
        lastSeen: now,
        category: KeywordCategory.promotional,
        isActive: true,
      ),
      SpamKeyword(
        id: 'default_2',
        keyword: 'winner',
        weight: 0.9,
        frequency: 3,
        firstSeen: now,
        lastSeen: now,
        category: KeywordCategory.lottery,
        isActive: true,
      ),
      SpamKeyword(
        id: 'default_3',
        keyword: 'urgent',
        weight: 0.7,
        frequency: 8,
        firstSeen: now,
        lastSeen: now,
        category: KeywordCategory.general,
        isActive: true,
      ),
    ]);

    _webConfig = AppConfig.defaultConfig();

    _logger.i('Web storage initialized with ${_webKeywords.length} keywords');
    return true;
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    _logger.i('Creating database tables...');

    // SMS Messages table
    await db.execute('''
      CREATE TABLE $_smsTable (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_classified INTEGER NOT NULL DEFAULT 0,
        classification TEXT,
        confidence REAL,
        detected_keywords TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // Classifications table
    await db.execute('''
      CREATE TABLE $_classificationsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sms_id TEXT NOT NULL,
        classification TEXT NOT NULL,
        confidence REAL NOT NULL,
        detected_keywords TEXT NOT NULL,
        classified_at INTEGER NOT NULL,
        model_version TEXT NOT NULL,
        is_user_feedback INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (sms_id) REFERENCES $_smsTable (id) ON DELETE CASCADE
      )
    ''');

    // Spam Keywords table
    await db.execute('''
      CREATE TABLE $_keywordsTable (
        id TEXT PRIMARY KEY,
        keyword TEXT NOT NULL UNIQUE,
        weight REAL NOT NULL,
        frequency INTEGER NOT NULL DEFAULT 1,
        first_seen INTEGER NOT NULL,
        last_seen INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        category TEXT NOT NULL DEFAULT 'general',
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // App Configuration table
    await db.execute('''
      CREATE TABLE $_configTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        telegram_bot_token TEXT NOT NULL,
        telegram_chat_id TEXT NOT NULL,
        spam_threshold REAL NOT NULL DEFAULT 0.5,
        auto_notify INTEGER NOT NULL DEFAULT 1,
        enable_learning INTEGER NOT NULL DEFAULT 1,
        max_sms_history INTEGER NOT NULL DEFAULT 10000,
        model_version TEXT NOT NULL DEFAULT '1.0.0',
        last_updated INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // Statistics table
    await db.execute('''
      CREATE TABLE $_statsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        metric_name TEXT NOT NULL,
        metric_value REAL NOT NULL,
        recorded_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        date_key TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_sms_timestamp ON $_smsTable (timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_sms_classification ON $_smsTable (classification)',
    );
    await db.execute(
      'CREATE INDEX idx_classifications_sms_id ON $_classificationsTable (sms_id)',
    );
    await db.execute(
      'CREATE INDEX idx_keywords_keyword ON $_keywordsTable (keyword)',
    );
    await db.execute(
      'CREATE INDEX idx_keywords_active ON $_keywordsTable (is_active)',
    );
    await db.execute('CREATE INDEX idx_stats_date ON $_statsTable (date_key)');

    _logger.i('Database tables created successfully');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');
    // Add migration logic here when needed
  }

  /// Get database instance
  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Insert SMS message
  Future<bool> insertSmsMessage(SmsMessage smsMessage) async {
    try {
      // Web platform compatibility
      if (kIsWeb) {
        _webSmsMessages.add(smsMessage);
        // Keep only last 100 messages in memory
        if (_webSmsMessages.length > 100) {
          _webSmsMessages.removeAt(0);
        }
        _logger.d('Inserted SMS message: ${smsMessage.id} (web)');
        return true;
      }

      await database.insert(_smsTable, {
        'id': smsMessage.id,
        'sender': smsMessage.sender,
        'body': smsMessage.body,
        'timestamp': smsMessage.timestamp.millisecondsSinceEpoch,
        'is_classified': smsMessage.isClassified ? 1 : 0,
        'classification': smsMessage.classification,
        'confidence': smsMessage.confidence,
        'detected_keywords': smsMessage.detectedKeywords?.join(','),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      _logger.d('Inserted SMS message: ${smsMessage.id}');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert SMS message: ${smsMessage.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Update SMS message with classification
  Future<bool> updateSmsMessageClassification(
    String smsId,
    ClassificationResult result,
  ) async {
    try {
      final updateCount = await database.update(
        _smsTable,
        {
          'is_classified': 1,
          'classification': result.classification,
          'confidence': result.confidence,
          'detected_keywords': result.detectedKeywords.join(','),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [smsId],
      );

      if (updateCount > 0) {
        _logger.d('Updated SMS message classification: $smsId');
        return true;
      } else {
        _logger.w('No SMS message found with id: $smsId');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update SMS message classification: $smsId',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Insert classification result
  Future<bool> insertClassificationResult(ClassificationResult result) async {
    try {
      await database.insert(_classificationsTable, {
        'sms_id': result.smsId,
        'classification': result.classification,
        'confidence': result.confidence,
        'detected_keywords': result.detectedKeywords.join(','),
        'classified_at': result.classifiedAt.millisecondsSinceEpoch,
        'model_version': result.modelVersion,
      });

      _logger.d('Inserted classification result for SMS: ${result.smsId}');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert classification result: ${result.smsId}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get SMS messages with optional filters
  Future<List<SmsMessage>> getSmsMessages({
    int? limit,
    String? classification,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Web platform compatibility
      if (kIsWeb) {
        var messages = List<SmsMessage>.from(_webSmsMessages);

        // Apply filters
        if (classification != null) {
          messages = messages
              .where((m) => m.classification == classification)
              .toList();
        }

        if (fromDate != null) {
          messages = messages
              .where((m) => m.timestamp.isAfter(fromDate))
              .toList();
        }

        if (toDate != null) {
          messages = messages
              .where((m) => m.timestamp.isBefore(toDate))
              .toList();
        }

        // Sort by timestamp descending
        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Apply limit
        if (limit != null && messages.length > limit) {
          messages = messages.take(limit).toList();
        }

        _logger.d('Retrieved ${messages.length} SMS messages (web)');
        return messages;
      }

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (classification != null) {
        whereClause += 'classification = ?';
        whereArgs.add(classification);
      }

      if (fromDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'timestamp >= ?';
        whereArgs.add(fromDate.millisecondsSinceEpoch);
      }

      if (toDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'timestamp <= ?';
        whereArgs.add(toDate.millisecondsSinceEpoch);
      }

      final result = await database.query(
        _smsTable,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      final messages = result.map((row) => _smsMessageFromMap(row)).toList();
      _logger.d('Retrieved ${messages.length} SMS messages');

      return messages;
    } catch (e, stackTrace) {
      _logger.e('Failed to get SMS messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get recent unclassified SMS messages
  Future<List<SmsMessage>> getUnclassifiedMessages({int limit = 100}) async {
    try {
      final result = await database.query(
        _smsTable,
        where: 'is_classified = ?',
        whereArgs: [0],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      final messages = result.map((row) => _smsMessageFromMap(row)).toList();
      _logger.d('Retrieved ${messages.length} unclassified SMS messages');

      return messages;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get unclassified SMS messages',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Insert or update spam keyword
  Future<bool> insertOrUpdateSpamKeyword(SpamKeyword keyword) async {
    try {
      await database.insert(_keywordsTable, {
        'id': keyword.id,
        'keyword': keyword.keyword,
        'weight': keyword.weight,
        'frequency': keyword.frequency,
        'first_seen': keyword.firstSeen.millisecondsSinceEpoch,
        'last_seen': keyword.lastSeen.millisecondsSinceEpoch,
        'is_active': keyword.isActive ? 1 : 0,
        'category': keyword.category.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      _logger.d('Inserted/updated spam keyword: ${keyword.keyword}');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert/update spam keyword: ${keyword.keyword}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get spam keywords
  Future<List<SpamKeyword>> getSpamKeywords({bool activeOnly = true}) async {
    try {
      // Web platform compatibility
      if (kIsWeb) {
        final keywords = activeOnly
            ? _webKeywords.where((k) => k.isActive).toList()
            : _webKeywords;
        _logger.d('Retrieved ${keywords.length} spam keywords (web)');
        return keywords;
      }

      final result = await database.query(
        _keywordsTable,
        where: activeOnly ? 'is_active = ?' : null,
        whereArgs: activeOnly ? [1] : null,
        orderBy: 'weight DESC, frequency DESC',
      );

      final keywords = result.map((row) => _spamKeywordFromMap(row)).toList();
      _logger.d('Retrieved ${keywords.length} spam keywords');

      return keywords;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get spam keywords',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Save app configuration
  Future<bool> saveAppConfig(AppConfig config) async {
    try {
      await database.insert(_configTable, {
        'id': 1,
        'telegram_bot_token': config.telegramBotToken,
        'telegram_chat_id': config.telegramChatId,
        'spam_threshold': config.spamThreshold,
        'auto_notify': config.autoNotify ? 1 : 0,
        'enable_learning': config.enableLearning ? 1 : 0,
        'max_sms_history': config.maxSmsHistory,
        'model_version': config.modelVersion,
        'last_updated': config.lastUpdated.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      _logger.d('Saved app configuration');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to save app configuration',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get app configuration
  Future<AppConfig?> getAppConfig() async {
    try {
      final result = await database.query(
        _configTable,
        where: 'id = ?',
        whereArgs: [1],
      );

      if (result.isNotEmpty) {
        final config = _appConfigFromMap(result.first);
        _logger.d('Retrieved app configuration');
        return config;
      } else {
        _logger.d('No app configuration found');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get app configuration',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    try {
      final smsCount =
          Sqflite.firstIntValue(
            await database.rawQuery('SELECT COUNT(*) FROM $_smsTable'),
          ) ??
          0;

      final spamCount =
          Sqflite.firstIntValue(
            await database.rawQuery(
              'SELECT COUNT(*) FROM $_smsTable WHERE classification = ?',
              ['spam'],
            ),
          ) ??
          0;

      final hamCount =
          Sqflite.firstIntValue(
            await database.rawQuery(
              'SELECT COUNT(*) FROM $_smsTable WHERE classification = ?',
              ['ham'],
            ),
          ) ??
          0;

      final unclassifiedCount =
          Sqflite.firstIntValue(
            await database.rawQuery(
              'SELECT COUNT(*) FROM $_smsTable WHERE is_classified = ?',
              [0],
            ),
          ) ??
          0;

      final keywordsCount =
          Sqflite.firstIntValue(
            await database.rawQuery(
              'SELECT COUNT(*) FROM $_keywordsTable WHERE is_active = ?',
              [1],
            ),
          ) ??
          0;

      return {
        'total_sms': smsCount,
        'spam_count': spamCount,
        'ham_count': hamCount,
        'unclassified_count': unclassifiedCount,
        'active_keywords_count': keywordsCount,
        'spam_rate': smsCount > 0 ? (spamCount / smsCount) : 0.0,
      };
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get database statistics',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Clean old SMS messages to maintain database size
  Future<int> cleanOldMessages({int keepCount = 10000}) async {
    try {
      // Get the timestamp of the message at the keepCount position
      final result = await database.rawQuery(
        '''
        SELECT timestamp FROM $_smsTable 
        ORDER BY timestamp DESC 
        LIMIT 1 OFFSET ?
      ''',
        [keepCount],
      );

      if (result.isNotEmpty) {
        final cutoffTimestamp = result.first['timestamp'] as int;

        final deletedCount = await database.delete(
          _smsTable,
          where: 'timestamp < ?',
          whereArgs: [cutoffTimestamp],
        );

        _logger.i('Cleaned $deletedCount old SMS messages');
        return deletedCount;
      }

      return 0;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to clean old messages',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  /// Record statistics
  Future<bool> recordStatistic(String metricName, double value) async {
    try {
      final dateKey = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // YYYY-MM-DD

      await database.insert(_statsTable, {
        'metric_name': metricName,
        'metric_value': value,
        'date_key': dateKey,
      });

      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to record statistic: $metricName',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Convert database row to SmsMessage
  SmsMessage _smsMessageFromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'] as String,
      sender: map['sender'] as String,
      body: map['body'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isClassified: (map['is_classified'] as int) == 1,
      classification: map['classification'] as String?,
      confidence: map['confidence'] as double?,
      detectedKeywords: map['detected_keywords'] != null
          ? (map['detected_keywords'] as String)
                .split(',')
                .where((s) => s.isNotEmpty)
                .toList()
          : null,
    );
  }

  /// Convert database row to SpamKeyword
  SpamKeyword _spamKeywordFromMap(Map<String, dynamic> map) {
    return SpamKeyword(
      id: map['id'] as String,
      keyword: map['keyword'] as String,
      weight: map['weight'] as double,
      frequency: map['frequency'] as int,
      firstSeen: DateTime.fromMillisecondsSinceEpoch(map['first_seen'] as int),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int),
      isActive: (map['is_active'] as int) == 1,
      category: KeywordCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => KeywordCategory.general,
      ),
    );
  }

  /// Convert database row to AppConfig
  AppConfig _appConfigFromMap(Map<String, dynamic> map) {
    return AppConfig(
      telegramBotToken: map['telegram_bot_token'] as String,
      telegramChatId: map['telegram_chat_id'] as String,
      spamThreshold: map['spam_threshold'] as double,
      autoNotify: (map['auto_notify'] as int) == 1,
      enableLearning: (map['enable_learning'] as int) == 1,
      maxSmsHistory: map['max_sms_history'] as int,
      modelVersion: map['model_version'] as String,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['last_updated'] as int,
      ),
    );
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.i('Database connection closed');
    }
  }
}
