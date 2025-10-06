import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

import '../models/sms_message.dart';
import '../models/classification_result.dart';
import '../models/app_config.dart';

/// Telegram notification service for sending classification results
class TelegramNotificationService {
  static final TelegramNotificationService _instance =
      TelegramNotificationService._internal();
  factory TelegramNotificationService() => _instance;
  TelegramNotificationService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio();

  AppConfig? _config;
  bool _isInitialized = false;

  // Telegram Bot API endpoint
  static const String _baseUrl = 'https://api.telegram.org/bot';

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Initialize the Telegram service with configuration
  Future<bool> initialize(AppConfig config) async {
    try {
      _logger.i('Initializing Telegram notification service...');

      _config = config;

      // Configure Dio with default headers and timeouts
      _dio.options = BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      );

      // Add request/response interceptors for logging
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false, // Don't log request body for security
          responseBody: false, // Don't log response body for performance
          logPrint: (object) => _logger.d(object.toString()),
        ),
      );

      // Test connection with getMe API call
      final isConnected = await testConnection();
      if (!isConnected) {
        _logger.w('Telegram bot connection test failed');
        return false;
      }

      _isInitialized = true;
      _logger.i('Telegram notification service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize Telegram service: $e');
      return false;
    }
  }

  /// Test Telegram bot connection
  Future<bool> testConnection() async {
    try {
      if (_config == null || _config!.telegramBotToken.isEmpty) {
        _logger.w('Telegram bot token not configured');
        return false;
      }

      _logger.i('Testing Telegram bot connection...');

      final response = await _dio.get(
        '$_baseUrl${_config!.telegramBotToken}/getMe',
      );

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final botInfo = response.data['result'];
        _logger.i(
          'Connected to Telegram bot: ${botInfo['first_name']} (@${botInfo['username']})',
        );
        return true;
      } else {
        _logger.e('Telegram bot connection failed: ${response.data}');
        return false;
      }
    } catch (e) {
      _logger.e('Error testing Telegram connection: $e');
      return false;
    }
  }

  /// Send spam notification to Telegram
  Future<bool> sendSpamNotification({
    required SmsMessage smsMessage,
    required ClassificationResult classification,
  }) async {
    try {
      if (!_isInitialized || _config == null) {
        _logger.w('Telegram service not initialized');
        return false;
      }

      if (!_config!.autoNotify) {
        _logger.i(
          'Auto notifications disabled, skipping Telegram notification',
        );
        return true;
      }

      _logger.i(
        'Sending spam notification to Telegram for SMS: ${smsMessage.id}',
      );

      // Create formatted message
      final message = _formatSpamNotification(smsMessage, classification);

      // Send message with retry logic
      return await _sendMessageWithRetry(message);
    } catch (e) {
      _logger.e('Error sending Telegram spam notification: $e');
      return false;
    }
  }

  /// Send test notification
  Future<bool> sendTestNotification() async {
    try {
      if (!_isInitialized || _config == null) {
        _logger.w('Telegram service not initialized');
        return false;
      }

      _logger.i('Sending test notification to Telegram');

      final timestamp = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());
      final message =
          '🧪 *Test Notification*\n\n'
          '✅ SMS Spam Detector is working correctly!\n\n'
          '📱 Service: Active\n'
          '🤖 Telegram Bot: Connected\n'
          '⏰ Time: $timestamp\n\n'
          '_This is a test message from your SMS Spam Detection app._';

      return await _sendMessageWithRetry(message);
    } catch (e) {
      _logger.e('Error sending test notification: $e');
      return false;
    }
  }

  /// Send a status message (for general notifications)
  Future<bool> sendStatusMessage(String message) async {
    try {
      if (!_isInitialized || _config == null) {
        _logger.w('Telegram service not initialized');
        return false;
      }

      _logger.i('Sending status message to Telegram');
      return await _sendMessageWithRetry(message);
    } catch (e) {
      _logger.e('Error sending status message: $e');
      return false;
    }
  }

  /// Format spam notification message
  String _formatSpamNotification(
    SmsMessage smsMessage,
    ClassificationResult classification,
  ) {
    final timestamp = DateFormat(
      'MMM dd, yyyy HH:mm',
    ).format(smsMessage.timestamp);
    final confidence = (classification.confidence * 100).toStringAsFixed(1);

    String emoji = classification.classification == 'spam' ? '🚨' : 'ℹ️';
    String alertType = classification.classification == 'spam'
        ? 'SPAM DETECTED'
        : 'HAM MESSAGE';

    final message =
        '$emoji *$alertType*\n\n'
        '📱 *From:* ${smsMessage.sender}\n'
        '📄 *Message:* ${_truncateMessage(smsMessage.body, 200)}\n'
        '🎯 *Classification:* ${classification.classification.toUpperCase()}\n'
        '📊 *Confidence:* $confidence%\n'
        '⏰ *Received:* $timestamp\n';

    // Add detected keywords if available
    if (classification.detectedKeywords != null &&
        classification.detectedKeywords.isNotEmpty) {
      final keywords = classification.detectedKeywords.take(5).join(', ');
      return message + '🔍 *Keywords:* $keywords\n';
    }

    return message;
  }

  /// Send message with retry logic
  Future<bool> _sendMessageWithRetry(String message) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final success = await _sendMessage(message);
        if (success) {
          _logger.d('Telegram message sent successfully on attempt $attempt');
          return true;
        }
      } catch (e) {
        _logger.w('Telegram send attempt $attempt failed: $e');

        if (attempt < _maxRetries) {
          _logger.i('Retrying in ${_retryDelay.inSeconds} seconds...');
          await Future.delayed(_retryDelay);
        }
      }
    }

    _logger.e('Failed to send Telegram message after $_maxRetries attempts');
    return false;
  }

  /// Send message to Telegram
  Future<bool> _sendMessage(String message) async {
    try {
      if (_config == null) return false;

      final response = await _dio.post(
        '$_baseUrl${_config!.telegramBotToken}/sendMessage',
        data: {
          'chat_id': _config!.telegramChatId,
          'text': message,
          'parse_mode': 'Markdown',
          'disable_web_page_preview': true,
        },
      );

      if (response.statusCode == 200 && response.data['ok'] == true) {
        _logger.d('Telegram message sent successfully');
        return true;
      } else {
        _logger.e('Telegram API error: ${response.data}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sending Telegram message: $e');
      return false;
    }
  }

  /// Truncate message to specified length
  String _truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength - 3)}...';
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'bot_token_configured': _config?.telegramBotToken.isNotEmpty ?? false,
      'chat_id_configured': _config?.telegramChatId.isNotEmpty ?? false,
      'auto_notify_enabled': _config?.autoNotify ?? false,
      'service_type': 'telegram',
    };
  }

  /// Update configuration
  Future<bool> updateConfiguration(AppConfig newConfig) async {
    try {
      _logger.i('Updating Telegram service configuration');

      final wasInitialized = _isInitialized;
      _isInitialized = false;

      final success = await initialize(newConfig);

      if (!success && wasInitialized) {
        // Try to restore previous config if update failed
        if (_config != null) {
          await initialize(_config!);
        }
      }

      return success;
    } catch (e) {
      _logger.e('Error updating Telegram configuration: $e');
      return false;
    }
  }

  /// Send daily summary
  Future<bool> sendDailySummary({
    required int totalMessages,
    required int spamMessages,
    required int hamMessages,
  }) async {
    try {
      if (!_isInitialized || _config == null) {
        return false;
      }

      final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      final spamPercentage = totalMessages > 0
          ? (spamMessages / totalMessages * 100).toStringAsFixed(1)
          : '0.0';

      final message =
          '📊 *Daily SMS Summary - $date*\n\n'
          '📱 Total Messages: $totalMessages\n'
          '🚨 Spam Detected: $spamMessages\n'
          '✅ Ham Messages: $hamMessages\n'
          '📈 Spam Rate: $spamPercentage%\n\n'
          '_SMS Spam Detector Daily Report_';

      return await _sendMessageWithRetry(message);
    } catch (e) {
      _logger.e('Error sending daily summary: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
