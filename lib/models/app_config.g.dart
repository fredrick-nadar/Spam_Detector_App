// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
  telegramBotToken: json['telegramBotToken'] as String,
  telegramChatId: json['telegramChatId'] as String,
  geminiApiKey: json['geminiApiKey'] as String? ?? '',
  enableAiKeywords: json['enableAiKeywords'] as bool? ?? true,
  spamThreshold: (json['spamThreshold'] as num?)?.toDouble() ?? 0.5,
  autoNotify: json['autoNotify'] as bool? ?? true,
  notifyOnlySpam: json['notifyOnlySpam'] as bool? ?? false,
  enableLearning: json['enableLearning'] as bool? ?? true,
  maxSmsHistory: (json['maxSmsHistory'] as num?)?.toInt() ?? 10000,
  maxKeywordsPerSms: (json['maxKeywordsPerSms'] as num?)?.toInt() ?? 10,
  modelVersion: json['modelVersion'] as String? ?? '1.0.0',
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
  'telegramBotToken': instance.telegramBotToken,
  'telegramChatId': instance.telegramChatId,
  'geminiApiKey': instance.geminiApiKey,
  'enableAiKeywords': instance.enableAiKeywords,
  'spamThreshold': instance.spamThreshold,
  'autoNotify': instance.autoNotify,
  'notifyOnlySpam': instance.notifyOnlySpam,
  'enableLearning': instance.enableLearning,
  'maxSmsHistory': instance.maxSmsHistory,
  'maxKeywordsPerSms': instance.maxKeywordsPerSms,
  'modelVersion': instance.modelVersion,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};
