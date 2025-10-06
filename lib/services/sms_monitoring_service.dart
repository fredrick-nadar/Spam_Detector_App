import 'dart:async';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:sms_advanced/sms_advanced.dart';

import '../models/sms_message.dart' as models;

/// Service for monitoring and reading SMS messages on Android
class SmsMonitoringService {
  static final SmsMonitoringService _instance = SmsMonitoringService._internal();
  factory SmsMonitoringService() => _instance;
  SmsMonitoringService._internal();

  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();
  final SmsQuery _smsQuery = SmsQuery();
  final SmsReceiver _smsReceiver = SmsReceiver();
  final StreamController<models.SmsMessage> _smsStreamController = 
      StreamController<models.SmsMessage>.broadcast();
  
  Stream<models.SmsMessage> get smsStream => _smsStreamController.stream;
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;
  bool _isAndroid = false;
  StreamSubscription<SmsMessage>? _smsSubscription;

  /// Initialize the SMS monitoring service
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing SMS monitoring service...');
      
      // Check if platform is Android
      _isAndroid = Platform.isAndroid;
      if (!_isAndroid) {
        _logger.w('SMS monitoring only supported on Android platform');
        return false;
      }

      // Check permissions
      bool hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        _logger.w('SMS permissions not granted, will request at runtime');
      }

      _logger.i('SMS monitoring service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize SMS monitoring service: $e');
      return false;
    }
  }

  /// Check if SMS and Phone permissions are granted
  Future<bool> _checkPermissions() async {
    try {
      final smsStatus = await Permission.sms.status;
      final phoneStatus = await Permission.phone.status;
      
      _logger.i('SMS permission: ${smsStatus.isGranted}');
      _logger.i('Phone permission: ${phoneStatus.isGranted}');
      
      return smsStatus.isGranted && phoneStatus.isGranted;
    } catch (e) {
      _logger.e('Error checking permissions: $e');
      return false;
    }
  }

  /// Request SMS and Phone permissions from user
  Future<bool> requestPermissions() async {
    try {
      _logger.i('Requesting SMS and Phone permissions...');
      
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
        Permission.phone,
      ].request();
      
      final allGranted = statuses.values.every((status) => status.isGranted);
      _logger.i('Permissions granted: $allGranted');
      
      return allGranted;
    } catch (e) {
      _logger.e('Error requesting permissions: $e');
      return false;
    }
  }

  /// Start monitoring incoming SMS messages
  Future<bool> startMonitoring() async {
    try {
      if (!_isAndroid) {
        _logger.e('SMS monitoring only supported on Android');
        return false;
      }

      if (_isMonitoring) {
        _logger.w('SMS monitoring already active');
        return true;
      }

      _logger.i('Starting SMS monitoring...');

      // Listen to incoming SMS using SmsReceiver
      _smsSubscription = _smsReceiver.onSmsReceived!.listen(
        (SmsMessage message) {
          _onNewSmsReceived(message);
        },
        onError: (error) {
          _logger.e('SMS receiver error: $error');
        },
      );

      _isMonitoring = true;
      _logger.i('SMS monitoring started - listening for incoming SMS');
      return true;
    } catch (e) {
      _logger.e('Failed to start SMS monitoring: $e');
      return false;
    }
  }

  /// Stop monitoring incoming SMS messages
  Future<void> stopMonitoring() async {
    try {
      if (!_isMonitoring) {
        _logger.w('SMS monitoring is not active');
        return;
      }

      _logger.i('Stopping SMS monitoring...');
      
      // Cancel the subscription
      await _smsSubscription?.cancel();
      _smsSubscription = null;
      
      _isMonitoring = false;
      _logger.i('SMS monitoring stopped successfully');
    } catch (e) {
      _logger.e('Error stopping SMS monitoring: $e');
    }
  }

  /// Handle new SMS received
  void _onNewSmsReceived(SmsMessage message) {
    try {
      _logger.i('New SMS received from ${message.address}');
      
      // Convert to app's SMS message format
      final smsMessage = _convertToAppSmsMessage(message);
      
      // Add to stream for processing
      _smsStreamController.add(smsMessage);
    } catch (e) {
      _logger.e('Error processing new SMS: $e');
    }
  }

  /// Convert SmsMessage from plugin to app's SmsMessage model
  models.SmsMessage _convertToAppSmsMessage(SmsMessage message) {
    return models.SmsMessage(
      id: _uuid.v4(),
      sender: message.address ?? 'Unknown',
      body: message.body ?? '',
      timestamp: message.date ?? DateTime.now(),
    );
  }

  /// Get recent SMS messages from inbox
  Future<List<models.SmsMessage>> getRecentMessages({int limit = 50}) async {
    try {
      if (!_isAndroid) {
        _logger.w('SMS reading only supported on Android');
        return [];
      }

      _logger.i('Fetching recent SMS messages from inbox...');

      // Query inbox messages using SmsQuery
      final List<SmsMessage> inboxMessages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.Inbox],
        count: limit,
      );

      if (inboxMessages.isEmpty) {
        _logger.i('No SMS messages found in inbox');
        return [];
      }

      // Convert to app's SMS message format
      final List<models.SmsMessage> messages = inboxMessages
          .map((msg) => _convertToAppSmsMessage(msg))
          .toList();

      _logger.i('Fetched ${messages.length} SMS messages from inbox');
      return messages;
    } catch (e) {
      _logger.e('Error fetching recent messages: $e');
      return [];
    }
  }

  /// Get all SMS messages from inbox
  Future<List<models.SmsMessage>> getAllInboxMessages() async {
    try {
      if (!_isAndroid) {
        _logger.w('SMS reading only supported on Android');
        return [];
      }

      _logger.i('Fetching all SMS messages from inbox...');

      // Query all inbox messages
      final List<SmsMessage> inboxMessages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.Inbox],
      );

      if (inboxMessages.isEmpty) {
        _logger.i('No SMS messages found');
        return [];
      }

      // Sort by date (newest first)
      final sortedMessages = inboxMessages.toList();
      sortedMessages.sort((a, b) {
        final dateA = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      // Convert to app's SMS message format
      final List<models.SmsMessage> messages = sortedMessages
          .map((msg) => _convertToAppSmsMessage(msg))
          .toList();

      _logger.i('Fetched ${messages.length} total SMS messages');
      return messages;
    } catch (e) {
      _logger.e('Error fetching all inbox messages: $e');
      return [];
    }
  }

  /// Search messages by query string
  Future<List<models.SmsMessage>> searchMessages(String query) async {
    try {
      if (!_isAndroid) return [];

      _logger.i('Searching SMS messages for: $query');

      // Get recent messages and filter locally
      final allMessages = await getRecentMessages(limit: 500);
      final filteredMessages = allMessages.where((message) {
        return message.body.toLowerCase().contains(query.toLowerCase()) ||
            message.sender.toLowerCase().contains(query.toLowerCase());
      }).toList();

      _logger.i('Found ${filteredMessages.length} messages matching query');
      return filteredMessages;
    } catch (e) {
      _logger.e('Error searching messages: $e');
      return [];
    }
  }

  /// Get message statistics
  Future<Map<String, int>> getMessageStats() async {
    try {
      if (!_isAndroid) {
        return {'total': 0, 'unread': 0, 'today': 0};
      }

      final messages = await getRecentMessages(limit: 500);
      final now = DateTime.now();

      return {
        'total': messages.length,
        'unread': messages.where((m) => !m.isClassified).length,
        'today': messages.where((m) {
          return m.timestamp.day == now.day &&
              m.timestamp.month == now.month &&
              m.timestamp.year == now.year;
        }).length,
      };
    } catch (e) {
      _logger.e('Error getting message stats: $e');
      return {'total': 0, 'unread': 0, 'today': 0};
    }
  }

  /// Dispose resources
  void dispose() {
    _smsSubscription?.cancel();
    _smsStreamController.close();
  }
}
