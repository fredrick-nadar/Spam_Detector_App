import 'dart:async';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/sms_message.dart';

class SmsMonitoringService {
  static final SmsMonitoringService _instance =
      SmsMonitoringService._internal();
  factory SmsMonitoringService() => _instance;
  SmsMonitoringService._internal();

  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  // Stream controllers for real-time SMS monitoring
  final StreamController<SmsMessage> _smsStreamController =
      StreamController<SmsMessage>.broadcast();

  Stream<SmsMessage> get smsStream => _smsStreamController.stream;

  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  // Mock data for demonstration
  Timer? _mockTimer;
  final Random _random = Random();

  // Sample SMS messages for demonstration
  final List<Map<String, dynamic>> _sampleMessages = [
    {
      'sender': '+1234567890',
      'body': r'Congratulations! You have won $1000. Click here to claim: http://fake-link.com',
      'isSpam': true
    },
    {
      'sender': 'AMAZON',
      'body': 'Your package will be delivered today between 2-4 PM',
      'isSpam': false
    },
    {
      'sender': '+9876543210',
      'body': 'URGENT: Your account will be suspended. Verify now at fake-bank.com',
      'isSpam': true
    },
    {
      'sender': 'Mom',
      'body': 'Don\'t forget to pick up groceries on your way home',
      'isSpam': false
    },
    {
      'sender': 'PROMO123',
      'body': 'LIMITED TIME: Get 90% off! Act now before it\'s too late!',
      'isSpam': true
    },
    {
      'sender': 'BANK',
      'body': r'Your account balance is $1,234.56 as of today',
      'isSpam': false
    },
  ];

  /// Initialize SMS monitoring service
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing SMS monitoring service...');

      // Check permissions (for real implementation)
      bool hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        _logger.w('SMS permissions not granted');
        // For demo, we'll continue anyway
      }

      _logger.i('SMS monitoring service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize SMS monitoring service: $e');
      return false;
    }
  }

  /// Check and request necessary permissions
  Future<bool> _checkPermissions() async {
    try {
      // Check SMS permission
      PermissionStatus smsStatus = await Permission.sms.status;
      if (smsStatus != PermissionStatus.granted) {
        smsStatus = await Permission.sms.request();
      }

      // Check phone permission
      PermissionStatus phoneStatus = await Permission.phone.status;
      if (phoneStatus != PermissionStatus.granted) {
        phoneStatus = await Permission.phone.request();
      }

      bool allGranted = smsStatus == PermissionStatus.granted &&
                       phoneStatus == PermissionStatus.granted;

      _logger.i('SMS permission: $smsStatus, Phone permission: $phoneStatus');
      return allGranted;
    } catch (e) {
      _logger.e('Error checking permissions: $e');
      return false;
    }
  }

  /// Start monitoring for incoming SMS messages
  Future<bool> startMonitoring() async {
    try {
      if (_isMonitoring) {
        _logger.w('SMS monitoring is already active');
        return true;
      }

      _logger.i('Starting SMS monitoring...');
      
      // For demonstration, we'll simulate incoming SMS messages
      _startMockMessageGeneration();
      
      _isMonitoring = true;
      _logger.i('SMS monitoring started successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to start SMS monitoring: $e');
      return false;
    }
  }

  /// Stop monitoring SMS messages
  Future<void> stopMonitoring() async {
    try {
      if (!_isMonitoring) {
        _logger.w('SMS monitoring is not active');
        return;
      }

      _logger.i('Stopping SMS monitoring...');
      
      _mockTimer?.cancel();
      _mockTimer = null;
      
      _isMonitoring = false;
      _logger.i('SMS monitoring stopped successfully');
    } catch (e) {
      _logger.e('Error stopping SMS monitoring: $e');
    }
  }

  /// Start generating mock SMS messages for demonstration
  void _startMockMessageGeneration() {
    // Generate a new message every 30-60 seconds for demo
    _mockTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      _generateMockMessage();
    });

    // Generate first message after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _generateMockMessage();
    });
  }

  /// Generate a mock SMS message
  void _generateMockMessage() {
    try {
      final sample = _sampleMessages[_random.nextInt(_sampleMessages.length)];
      
      final smsMessage = SmsMessage(
        id: _uuid.v4(),
        sender: sample['sender'] as String,
        body: sample['body'] as String,
        timestamp: DateTime.now(),
      );

      _logger.i('Generated mock SMS from ${smsMessage.sender}');
      _smsStreamController.add(smsMessage);
    } catch (e) {
      _logger.e('Error generating mock message: $e');
    }
  }

  /// Get recent SMS messages (mock implementation)
  Future<List<SmsMessage>> getRecentMessages({int limit = 50}) async {
    try {
      _logger.i('Fetching recent SMS messages (mock)...');
      
      final List<SmsMessage> messages = [];
      final now = DateTime.now();
      
      // Generate some historical messages
      for (int i = 0; i < limit && i < _sampleMessages.length * 3; i++) {
        final sample = _sampleMessages[i % _sampleMessages.length];
        final messageTime = now.subtract(Duration(
          hours: _random.nextInt(24 * 7), // Last week
          minutes: _random.nextInt(60),
        ));
        
        final smsMessage = SmsMessage(
          id: _uuid.v4(),
          sender: sample['sender'] as String,
          body: sample['body'] as String,
          timestamp: messageTime,
        );
        
        messages.add(smsMessage);
      }
      
      // Sort by timestamp (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _logger.i('Fetched ${messages.length} mock SMS messages');
      return messages;
    } catch (e) {
      _logger.e('Error fetching recent messages: $e');
      return [];
    }
  }

  /// Search SMS messages by query (mock implementation)
  Future<List<SmsMessage>> searchMessages(String query) async {
    try {
      _logger.i('Searching SMS messages for: $query');
      
      final allMessages = await getRecentMessages(limit: 100);
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

  /// Get message count by type (mock implementation)
  Future<Map<String, int>> getMessageStats() async {
    try {
      final messages = await getRecentMessages(limit: 100);
      
      return {
        'total': messages.length,
        'unread': messages.where((m) => !m.isClassified).length,
        'today': messages.where((m) {
          final now = DateTime.now();
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
    _mockTimer?.cancel();
    _smsStreamController.close();
  }
}