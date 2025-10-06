import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

@JsonSerializable()
class AppConfig {
  final String telegramBotToken;
  final String telegramChatId;
  final String geminiApiKey;
  final bool enableAiKeywords;
  final double spamThreshold;
  final bool autoNotify;
  final bool notifyOnlySpam;
  final bool enableLearning;
  final int maxSmsHistory;
  final int maxKeywordsPerSms;
  final String modelVersion;
  final DateTime lastUpdated;

  const AppConfig({
    required this.telegramBotToken,
    required this.telegramChatId,
    this.geminiApiKey = '',
    this.enableAiKeywords = true,
    this.spamThreshold = 0.5,
    this.autoNotify = true,
    this.notifyOnlySpam = false,
    this.enableLearning = true,
    this.maxSmsHistory = 10000,
    this.maxKeywordsPerSms = 10,
    this.modelVersion = '1.0.0',
    required this.lastUpdated,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigToJson(this);

  factory AppConfig.defaultConfig() {
    return AppConfig(
      telegramBotToken: '',
      telegramChatId: '',
      lastUpdated: DateTime.now(),
    );
  }

  AppConfig copyWith({
    String? telegramBotToken,
    String? telegramChatId,
    String? geminiApiKey,
    bool? enableAiKeywords,
    double? spamThreshold,
    bool? autoNotify,
    bool? notifyOnlySpam,
    bool? enableLearning,
    int? maxSmsHistory,
    int? maxKeywordsPerSms,
    String? modelVersion,
    DateTime? lastUpdated,
  }) {
    return AppConfig(
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      enableAiKeywords: enableAiKeywords ?? this.enableAiKeywords,
      spamThreshold: spamThreshold ?? this.spamThreshold,
      autoNotify: autoNotify ?? this.autoNotify,
      notifyOnlySpam: notifyOnlySpam ?? this.notifyOnlySpam,
      enableLearning: enableLearning ?? this.enableLearning,
      maxSmsHistory: maxSmsHistory ?? this.maxSmsHistory,
      maxKeywordsPerSms: maxKeywordsPerSms ?? this.maxKeywordsPerSms,
      modelVersion: modelVersion ?? this.modelVersion,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isConfigured {
    return telegramBotToken.isNotEmpty && telegramChatId.isNotEmpty;
  }

  bool get isAiConfigured {
    return geminiApiKey.isNotEmpty;
  }

  @override
  String toString() {
    return 'AppConfig(threshold: $spamThreshold, autoNotify: $autoNotify, '
        'notifyOnlySpam: $notifyOnlySpam, learning: $enableLearning, '
        'aiEnabled: $enableAiKeywords, configured: $isConfigured, '
        'aiConfigured: $isAiConfigured)';
  }
}
