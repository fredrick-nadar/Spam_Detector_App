import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

@JsonSerializable()
class AppConfig {
  final String telegramBotToken;
  final String telegramChatId;
  final double spamThreshold;
  final bool autoNotify;
  final bool enableLearning;
  final int maxSmsHistory;
  final String modelVersion;
  final DateTime lastUpdated;

  const AppConfig({
    required this.telegramBotToken,
    required this.telegramChatId,
    this.spamThreshold = 0.5,
    this.autoNotify = true,
    this.enableLearning = true,
    this.maxSmsHistory = 10000,
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
    double? spamThreshold,
    bool? autoNotify,
    bool? enableLearning,
    int? maxSmsHistory,
    String? modelVersion,
    DateTime? lastUpdated,
  }) {
    return AppConfig(
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      spamThreshold: spamThreshold ?? this.spamThreshold,
      autoNotify: autoNotify ?? this.autoNotify,
      enableLearning: enableLearning ?? this.enableLearning,
      maxSmsHistory: maxSmsHistory ?? this.maxSmsHistory,
      modelVersion: modelVersion ?? this.modelVersion,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isConfigured {
    return telegramBotToken.isNotEmpty && telegramChatId.isNotEmpty;
  }

  @override
  String toString() {
    return 'AppConfig(threshold: $spamThreshold, autoNotify: $autoNotify, '
        'learning: $enableLearning, configured: $isConfigured)';
  }
}
