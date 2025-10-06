import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

import '../models/sms_message.dart';
import '../models/classification_result.dart';
import '../models/app_config.dart';
import '../services/sms_monitoring_service.dart';
import '../services/spam_classification_service.dart';
import '../services/database_service.dart';
import '../services/telegram_notification_service.dart';

/// Main orchestrator service that coordinates all SMS spam detection operations
class SmsSpamDetectorService extends ChangeNotifier {
  static final SmsSpamDetectorService _instance =
      SmsSpamDetectorService._internal();
  factory SmsSpamDetectorService() => _instance;
  SmsSpamDetectorService._internal();

  final Logger _logger = Logger();

  // Service instances
  final SmsMonitoringService _smsService = SmsMonitoringService();
  final SpamClassificationService _classificationService =
      SpamClassificationService();
  final DatabaseService _databaseService = DatabaseService();
  final TelegramNotificationService _telegramService =
      TelegramNotificationService();

  // State
  bool _isInitialized = false;
  bool _isRunning = false;
  AppConfig? _currentConfig;
  StreamSubscription<SmsMessage>? _smsSubscription;

  // Statistics
  int _totalProcessed = 0;
  int _spamDetected = 0;
  int _hamDetected = 0;
  DateTime? _lastProcessedTime;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
  AppConfig? get currentConfig => _currentConfig;

  Map<String, dynamic> get statistics => {
    'total_processed': _totalProcessed,
    'spam_detected': _spamDetected,
    'ham_detected': _hamDetected,
    'spam_rate': _totalProcessed > 0 ? _spamDetected / _totalProcessed : 0.0,
    'last_processed': _lastProcessedTime?.toIso8601String(),
    'is_running': _isRunning,
  };

  /// Initialize the entire SMS spam detection system
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing SMS Spam Detector system...');

      // Initialize database first
      bool dbInitialized = await _databaseService.initialize();
      if (!dbInitialized) {
        _logger.e('Database initialization failed');
        return false;
      }

      // Load configuration
      _currentConfig = await _databaseService.getAppConfig();
      if (_currentConfig == null) {
        _logger.i('No configuration found, using default config');
        _currentConfig = AppConfig.defaultConfig();
        await _databaseService.saveAppConfig(_currentConfig!);
      }

      // Initialize classification service
      bool classificationInitialized = await _classificationService
          .initialize();
      if (!classificationInitialized) {
        _logger.e('Classification service initialization failed');
        return false;
      }

      // Initialize SMS monitoring
      bool smsInitialized = await _smsService.initialize();
      if (!smsInitialized) {
        _logger.e('SMS monitoring initialization failed');
        return false;
      }

      // Initialize Telegram service if configured
      if (_currentConfig!.isConfigured) {
        bool telegramInitialized = await _telegramService.initialize(
          _currentConfig!,
        );
        if (!telegramInitialized) {
          _logger.w(
            'Telegram service initialization failed - notifications disabled',
          );
        }
      }

      _isInitialized = true;
      _logger.i('SMS Spam Detector system initialized successfully');

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize SMS Spam Detector system',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Start the SMS monitoring and classification system
  Future<bool> start() async {
    if (!_isInitialized) {
      _logger.e('System not initialized. Call initialize() first.');
      return false;
    }

    if (_isRunning) {
      _logger.w('System is already running');
      return true;
    }

    try {
      _logger.i('Starting SMS spam detection system...');

      // Start SMS monitoring
      bool smsStarted = await _smsService.startMonitoring();
      if (!smsStarted) {
        _logger.e('Failed to start SMS monitoring');
        return false;
      }

      // Subscribe to SMS stream
      _smsSubscription = _smsService.smsStream.listen(
        _processSmsMessage,
        onError: (error) {
          _logger.e('Error in SMS stream: $error');
        },
      );

      // Process any existing unclassified messages
      await _processUnclassifiedMessages();

      _isRunning = true;
      _logger.i('SMS spam detection system started successfully');

      // Send startup notification if configured
      if (_currentConfig!.isConfigured && _currentConfig!.autoNotify) {
        await _telegramService.sendStatusMessage(
          '🚀 SMS Spam Detector started successfully and is now monitoring incoming messages.',
        );
      }

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to start SMS spam detection system',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Stop the SMS monitoring and classification system
  Future<void> stop() async {
    if (!_isRunning) {
      _logger.w('System is not running');
      return;
    }

    try {
      _logger.i('Stopping SMS spam detection system...');

      // Cancel SMS subscription
      await _smsSubscription?.cancel();
      _smsSubscription = null;

      // Stop SMS monitoring
      _smsService.stopMonitoring();

      _isRunning = false;
      _logger.i('SMS spam detection system stopped');

      // Send shutdown notification if configured
      if (_currentConfig!.isConfigured && _currentConfig!.autoNotify) {
        await _telegramService.sendStatusMessage(
          '⏹️ SMS Spam Detector has been stopped.',
        );
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _logger.e(
        'Error stopping SMS spam detection system',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Process incoming SMS message
  Future<void> _processSmsMessage(SmsMessage smsMessage) async {
    try {
      _logger.d('Processing new SMS: ${smsMessage.id}');

      // Store SMS in database
      await _databaseService.insertSmsMessage(smsMessage);

      // Classify the message
      final classificationResult = await _classificationService.classifyMessage(
        smsMessage,
      );

      // Store classification result
      await _databaseService.insertClassificationResult(classificationResult);
      await _databaseService.updateSmsMessageClassification(
        smsMessage.id,
        classificationResult,
      );

      // Update statistics
      _updateStatistics(classificationResult);

      // Send notification if configured and auto-notify is enabled
      if (_currentConfig!.isConfigured && _currentConfig!.autoNotify) {
        await _telegramService.sendSpamNotification(
          smsMessage: smsMessage,
          classification: classificationResult,
        );
      }

      // Record statistics
      await _databaseService.recordStatistic('messages_processed', 1);
      if (classificationResult.isSpam) {
        await _databaseService.recordStatistic('spam_detected', 1);
      }

      _lastProcessedTime = DateTime.now();
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to process SMS message: ${smsMessage.id}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Process existing unclassified messages
  Future<void> _processUnclassifiedMessages() async {
    try {
      final unclassifiedMessages = await _databaseService
          .getUnclassifiedMessages(limit: 100);

      if (unclassifiedMessages.isNotEmpty) {
        _logger.i(
          'Processing ${unclassifiedMessages.length} unclassified messages...',
        );

        for (final message in unclassifiedMessages) {
          final classificationResult = await _classificationService
              .classifyMessage(message);

          await _databaseService.insertClassificationResult(
            classificationResult,
          );
          await _databaseService.updateSmsMessageClassification(
            message.id,
            classificationResult,
          );

          _updateStatistics(classificationResult);
        }

        _logger.i(
          'Processed ${unclassifiedMessages.length} unclassified messages',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to process unclassified messages',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update system statistics
  void _updateStatistics(ClassificationResult result) {
    _totalProcessed++;
    if (result.isSpam) {
      _spamDetected++;
    } else {
      _hamDetected++;
    }
  }

  /// Update system configuration
  Future<bool> updateConfiguration(AppConfig newConfig) async {
    try {
      _logger.i('Updating system configuration...');

      // Save to database
      bool saved = await _databaseService.saveAppConfig(newConfig);
      if (!saved) {
        _logger.e('Failed to save configuration to database');
        return false;
      }

      // Update Telegram service if configuration changed
      if (newConfig.isConfigured &&
          (newConfig.telegramBotToken != _currentConfig?.telegramBotToken ||
              newConfig.telegramChatId != _currentConfig?.telegramChatId)) {
        bool telegramUpdated = await _telegramService.updateConfiguration(
          newConfig,
        );
        if (!telegramUpdated) {
          _logger.w('Failed to update Telegram configuration');
        }
      }

      _currentConfig = newConfig;
      _logger.i('System configuration updated successfully');

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update configuration',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Provide feedback for a message classification
  Future<bool> provideFeedback(String smsId, bool isActuallySpam) async {
    try {
      _logger.d('Providing feedback for SMS: $smsId, isSpam: $isActuallySpam');

      // Get the SMS message
      final messages = await _databaseService.getSmsMessages();
      final smsMessage = messages.firstWhere(
        (msg) => msg.id == smsId,
        orElse: () => throw StateError('Message not found'),
      );

      // Update keywords based on feedback
      await _classificationService.updateKeywords(
        smsMessage.body,
        isActuallySpam,
      );

      // Record feedback in database
      await _databaseService.insertClassificationResult(
        ClassificationResult(
          smsId: smsId,
          classification: isActuallySpam ? 'spam' : 'ham',
          confidence: 1.0, // User feedback has high confidence
          detectedKeywords: [],
          classifiedAt: DateTime.now(),
          modelVersion: 'user_feedback',
        ),
      );

      _logger.i('Feedback recorded for SMS: $smsId');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to provide feedback for SMS: $smsId',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Send test WhatsApp message
  Future<bool> sendTestMessage() async {
    if (!_currentConfig!.isConfigured) {
      _logger.w('Telegram not configured');
      return false;
    }

    return await _telegramService.sendTestNotification();
  }

  /// Get recent SMS messages
  Future<List<SmsMessage>> getRecentMessages({int limit = 50}) async {
    return await _databaseService.getSmsMessages(limit: limit);
  }

  /// Get system health status
  Map<String, dynamic> getSystemHealth() {
    return {
      'is_initialized': _isInitialized,
      'is_running': _isRunning,
      'sms_monitoring': _smsService.isMonitoring,
      'database_connected': _isInitialized,
      'whatsapp_configured': _currentConfig?.isConfigured ?? false,
      'classification_ready':
          _classificationService.getModelStatistics()['is_initialized'] ??
          false,
      'statistics': statistics,
    };
  }

  /// Send daily summary report
  Future<bool> sendDailySummary() async {
    try {
      if (!_currentConfig!.isConfigured) {
        return false;
      }

      final dbStats = await _databaseService.getDatabaseStatistics();
      final systemHealth = getSystemHealth();

      final summaryStats = {
        ...dbStats,
        ...systemHealth,
        'system_status': _isRunning ? 'Running' : 'Stopped',
        'uptime': _isRunning ? 'Active' : 'Inactive',
        'accuracy': 0.95, // This would be calculated from feedback data
        'avg_processing_time': 150, // This would be tracked
      };

      return await _telegramService.sendDailySummary(
        totalMessages: summaryStats['total_processed'],
        spamMessages: summaryStats['spam_detected'],
        hamMessages: summaryStats['ham_detected'],
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to send daily summary',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Cleanup old data
  Future<void> performMaintenance() async {
    try {
      _logger.i('Performing system maintenance...');

      // Clean old SMS messages
      final deletedCount = await _databaseService.cleanOldMessages(
        keepCount: _currentConfig?.maxSmsHistory ?? 10000,
      );

      if (deletedCount > 0) {
        _logger.i('Cleaned $deletedCount old SMS messages');
      }

      _logger.i('System maintenance completed');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to perform maintenance',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _logger.i('Disposing SMS Spam Detector service...');

    stop();
    _smsService.dispose();
    _telegramService.dispose();
    _databaseService.close();

    super.dispose();
  }
}
