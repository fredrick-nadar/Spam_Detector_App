import 'package:json_annotation/json_annotation.dart';

part 'sms_message.g.dart';

@JsonSerializable()
class SmsMessage {
  final String id;
  final String sender;
  final String body;
  final DateTime timestamp;
  final bool isClassified;
  final String? classification; // 'spam', 'ham', or null
  final double? confidence;
  final List<String>? detectedKeywords;

  const SmsMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
    this.isClassified = false,
    this.classification,
    this.confidence,
    this.detectedKeywords,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) =>
      _$SmsMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SmsMessageToJson(this);

  SmsMessage copyWith({
    String? id,
    String? sender,
    String? body,
    DateTime? timestamp,
    bool? isClassified,
    String? classification,
    double? confidence,
    List<String>? detectedKeywords,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isClassified: isClassified ?? this.isClassified,
      classification: classification ?? this.classification,
      confidence: confidence ?? this.confidence,
      detectedKeywords: detectedKeywords ?? this.detectedKeywords,
    );
  }

  @override
  String toString() {
    return 'SmsMessage(id: $id, sender: $sender, body: $body, '
        'classification: $classification, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmsMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
