// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
  telegramBotToken: json['telegramBotToken'] as String,
  telegramChatId: json['telegramChatId'] as String,
  spamThreshold: (json['spamThreshold'] as num?)?.toDouble() ?? 0.5,
  autoNotify: json['autoNotify'] as bool? ?? true,
  enableLearning: json['enableLearning'] as bool? ?? true,
  maxSmsHistory: (json['maxSmsHistory'] as num?)?.toInt() ?? 10000,
  modelVersion: json['modelVersion'] as String? ?? '1.0.0',
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
  'telegramBotToken': instance.telegramBotToken,
  'telegramChatId': instance.telegramChatId,
  'spamThreshold': instance.spamThreshold,
  'autoNotify': instance.autoNotify,
  'enableLearning': instance.enableLearning,
  'maxSmsHistory': instance.maxSmsHistory,
  'modelVersion': instance.modelVersion,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};
