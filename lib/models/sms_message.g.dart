// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmsMessage _$SmsMessageFromJson(Map<String, dynamic> json) => SmsMessage(
  id: json['id'] as String,
  sender: json['sender'] as String,
  body: json['body'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  isClassified: json['isClassified'] as bool? ?? false,
  classification: json['classification'] as String?,
  confidence: (json['confidence'] as num?)?.toDouble(),
  detectedKeywords: (json['detectedKeywords'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SmsMessageToJson(SmsMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender': instance.sender,
      'body': instance.body,
      'timestamp': instance.timestamp.toIso8601String(),
      'isClassified': instance.isClassified,
      'classification': instance.classification,
      'confidence': instance.confidence,
      'detectedKeywords': instance.detectedKeywords,
    };
