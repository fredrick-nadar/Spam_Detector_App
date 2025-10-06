import 'dart:math';
import 'package:logger/logger.dart';

/// NLP preprocessing service for cleaning and preparing SMS text data
class NlpPreprocessingService {
  static final NlpPreprocessingService _instance =
      NlpPreprocessingService._internal();
  factory NlpPreprocessingService() => _instance;
  NlpPreprocessingService._internal();

  final Logger _logger = Logger();

  /// Common English stop words to remove during preprocessing
  static const Set<String> _stopWords = {
    'a',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'by',
    'for',
    'from',
    'has',
    'he',
    'in',
    'is',
    'it',
    'its',
    'of',
    'on',
    'that',
    'the',
    'to',
    'was',
    'were',
    'will',
    'with',
    'you',
    'your',
    'i',
    'me',
    'my',
    'we',
    'our',
    'they',
    'them',
    'their',
    'this',
    'these',
    'have',
    'had',
    'been',
    'do',
    'does',
    'did',
    'can',
    'could',
    'should',
    'would',
    'may',
    'might',
    'must',
    'shall',
  };

  /// Common SMS abbreviations and their expansions
  static const Map<String, String> _smsAbbreviations = {
    'u': 'you',
    'ur': 'your',
    'r': 'are',
    'n': 'and',
    '2': 'to',
    '4': 'for',
    'w8': 'wait',
    'l8r': 'later',
    'b4': 'before',
    'c': 'see',
    'k': 'okay',
    'txt': 'text',
    'msg': 'message',
    'thx': 'thanks',
    'pls': 'please',
    'plz': 'please',
    'luv': 'love',
    'gr8': 'great',
    'cuz': 'because',
    'bcuz': 'because',
    'coz': 'because',
    'omg': 'oh my god',
    'lol': 'laugh out loud',
    'asap': 'as soon as possible',
    'fyi': 'for your information',
    'btw': 'by the way',
    'imo': 'in my opinion',
    'afaik': 'as far as i know',
    'w1n': 'win',
    'fr33': 'free',
    'f0r': 'for',
    'm0ney': 'money',
    'c4sh': 'cash',
    'ch3ap': 'cheap',
  };

  /// Spam-indicating patterns (for initial keyword detection)
  static final List<RegExp> _spamPatterns = [
    // Money/Financial patterns
    RegExp(
      r'\b(win|won|winner|prize|cash|money|\$\d+|free|claim)\b',
      caseSensitive: false,
    ),
    // Urgency patterns
    RegExp(
      r'\b(urgent|asap|immediately|now|today|expire|limited|offer)\b',
      caseSensitive: false,
    ),
    // Contact patterns
    RegExp(
      r'\b(call|text|reply|send|contact)\s*(now|asap|immediately)\b',
      caseSensitive: false,
    ),
    // Promotional patterns
    RegExp(
      r'\b(deal|discount|sale|offer|promotion|special)\b',
      caseSensitive: false,
    ),
    // Suspicious characters/numbers
    RegExp(r'[0-9]{4,}|[A-Z]{5,}|\b(STOP|END|CANCEL)\b', caseSensitive: false),
  ];

  /// Clean and preprocess SMS message text
  Future<ProcessedText> preprocessText(String rawText) async {
    try {
      _logger.d(
        'Preprocessing text: ${rawText.substring(0, min(50, rawText.length))}...',
      );

      final stopwatch = Stopwatch()..start();

      // Step 1: Initial cleaning
      String cleanedText = _initialCleaning(rawText);

      // Step 2: Expand abbreviations
      cleanedText = _expandAbbreviations(cleanedText);

      // Step 3: Normalize text
      cleanedText = _normalizeText(cleanedText);

      // Step 4: Tokenization
      final tokens = _tokenize(cleanedText);

      // Step 5: Remove stop words
      final filteredTokens = _removeStopWords(tokens);

      // Step 6: Extract features
      final features = _extractFeatures(rawText, cleanedText, filteredTokens);

      // Step 7: Detect spam indicators
      final spamIndicators = _detectSpamIndicators(rawText, cleanedText);

      stopwatch.stop();

      final result = ProcessedText(
        originalText: rawText,
        cleanedText: cleanedText,
        tokens: filteredTokens,
        features: features,
        spamIndicators: spamIndicators,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      _logger.d(
        'Text preprocessing completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to preprocess text', error: e, stackTrace: stackTrace);
      return ProcessedText.error(rawText, e.toString());
    }
  }

  /// Initial text cleaning (remove HTML, normalize whitespace, etc.)
  String _initialCleaning(String text) {
    String cleaned = text;

    // Remove HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Remove URLs
    cleaned = cleaned.replaceAll(
      RegExp(r'https?://[^\s]+|www\.[^\s]+', caseSensitive: false),
      ' URL ',
    );

    // Remove email addresses
    cleaned = cleaned.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      ' EMAIL ',
    );

    // Normalize phone numbers
    cleaned = cleaned.replaceAll(
      RegExp(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'),
      ' PHONE ',
    );

    // Normalize excessive punctuation and special characters
    cleaned = cleaned.replaceAll(RegExp(r'[!]{2,}'), '!');
    cleaned = cleaned.replaceAll(RegExp(r'[?]{2,}'), '?');
    cleaned = cleaned.replaceAll(RegExp(r'[.]{2,}'), '...');

    // Remove excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned.trim();
  }

  /// Expand SMS abbreviations to full words
  String _expandAbbreviations(String text) {
    String expanded = text.toLowerCase();

    _smsAbbreviations.forEach((abbrev, expansion) {
      // Match whole words only
      expanded = expanded.replaceAll(RegExp(r'\b' + abbrev + r'\b'), expansion);
    });

    return expanded;
  }

  /// Normalize text (case, special characters, etc.)
  String _normalizeText(String text) {
    String normalized = text.toLowerCase();

    // Convert numbers written with letters/symbols
    normalized = normalized.replaceAll(RegExp(r'\b0\b'), 'o');
    normalized = normalized.replaceAll(RegExp(r'\b1\b'), 'i');
    normalized = normalized.replaceAll(RegExp(r'\b3\b'), 'e');
    normalized = normalized.replaceAll(RegExp(r'\b4\b'), 'a');
    normalized = normalized.replaceAll(RegExp(r'\b5\b'), 's');
    normalized = normalized.replaceAll(RegExp(r'\b7\b'), 't');

    // Remove most punctuation except important ones
    normalized = normalized.replaceAll(RegExp(r'[^\w\s\$\%\!\?]'), ' ');

    // Normalize whitespace again
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    return normalized.trim();
  }

  /// Tokenize text into individual words
  List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && token.length > 1)
        .toList();
  }

  /// Remove stop words from tokens
  List<String> _removeStopWords(List<String> tokens) {
    return tokens
        .where((token) => !_stopWords.contains(token.toLowerCase()))
        .toList();
  }

  /// Extract numerical and statistical features from text
  Map<String, double> _extractFeatures(
    String original,
    String cleaned,
    List<String> tokens,
  ) {
    return {
      'length': original.length.toDouble(),
      'word_count': tokens.length.toDouble(),
      'avg_word_length': tokens.isEmpty
          ? 0.0
          : tokens.map((t) => t.length).reduce((a, b) => a + b) / tokens.length,
      'uppercase_ratio': _calculateUppercaseRatio(original),
      'digit_ratio': _calculateDigitRatio(original),
      'special_char_ratio': _calculateSpecialCharRatio(original),
      'exclamation_count': original.split('!').length - 1.toDouble(),
      'question_count': original.split('?').length - 1.toDouble(),
      'dollar_sign_count': original.split('\$').length - 1.toDouble(),
      'url_count': RegExp(
        r'https?://|www\.',
      ).allMatches(original).length.toDouble(),
      'phone_pattern_count': RegExp(
        r'\d{3,}',
      ).allMatches(original).length.toDouble(),
    };
  }

  /// Calculate ratio of uppercase characters
  double _calculateUppercaseRatio(String text) {
    if (text.isEmpty) return 0.0;
    final uppercaseCount = text
        .split('')
        .where((c) => c.toUpperCase() == c && c != c.toLowerCase())
        .length;
    return uppercaseCount / text.length;
  }

  /// Calculate ratio of digit characters
  double _calculateDigitRatio(String text) {
    if (text.isEmpty) return 0.0;
    final digitCount = text
        .split('')
        .where((c) => RegExp(r'\d').hasMatch(c))
        .length;
    return digitCount / text.length;
  }

  /// Calculate ratio of special characters
  double _calculateSpecialCharRatio(String text) {
    if (text.isEmpty) return 0.0;
    final specialCount = text
        .split('')
        .where((c) => RegExp(r'[^\w\s]').hasMatch(c))
        .length;
    return specialCount / text.length;
  }

  /// Detect spam indicators in the text
  List<SpamIndicator> _detectSpamIndicators(String original, String cleaned) {
    final indicators = <SpamIndicator>[];

    for (final pattern in _spamPatterns) {
      final matches = pattern.allMatches(original);
      for (final match in matches) {
        indicators.add(
          SpamIndicator(
            type: _getIndicatorType(pattern),
            matchedText: match.group(0) ?? '',
            confidence: 0.7, // Base confidence for pattern matches
            position: match.start,
          ),
        );
      }
    }

    // Check for excessive caps
    if (_calculateUppercaseRatio(original) > 0.5) {
      indicators.add(
        SpamIndicator(
          type: SpamIndicatorType.excessiveCaps,
          matchedText: 'HIGH_CAPS_RATIO',
          confidence: 0.6,
          position: 0,
        ),
      );
    }

    // Check for excessive numbers
    if (_calculateDigitRatio(original) > 0.3) {
      indicators.add(
        SpamIndicator(
          type: SpamIndicatorType.excessiveNumbers,
          matchedText: 'HIGH_DIGIT_RATIO',
          confidence: 0.5,
          position: 0,
        ),
      );
    }

    return indicators;
  }

  /// Get spam indicator type from regex pattern
  SpamIndicatorType _getIndicatorType(RegExp pattern) {
    final patternString = pattern.pattern.toLowerCase();

    if (patternString.contains('win|won|prize|cash|money')) {
      return SpamIndicatorType.financial;
    } else if (patternString.contains('urgent|asap|immediately')) {
      return SpamIndicatorType.urgency;
    } else if (patternString.contains('call|text|reply')) {
      return SpamIndicatorType.contact;
    } else if (patternString.contains('deal|discount|sale')) {
      return SpamIndicatorType.promotional;
    } else {
      return SpamIndicatorType.general;
    }
  }

  /// Batch process multiple SMS texts
  Future<List<ProcessedText>> batchPreprocess(List<String> texts) async {
    _logger.i('Batch preprocessing ${texts.length} texts...');

    final results = <ProcessedText>[];
    final stopwatch = Stopwatch()..start();

    for (final text in texts) {
      final processed = await preprocessText(text);
      results.add(processed);
    }

    stopwatch.stop();
    _logger.i(
      'Batch preprocessing completed in ${stopwatch.elapsedMilliseconds}ms',
    );

    return results;
  }
}

/// Represents processed text with extracted features and indicators
class ProcessedText {
  final String originalText;
  final String cleanedText;
  final List<String> tokens;
  final Map<String, double> features;
  final List<SpamIndicator> spamIndicators;
  final int processingTimeMs;
  final String? error;

  const ProcessedText({
    required this.originalText,
    required this.cleanedText,
    required this.tokens,
    required this.features,
    required this.spamIndicators,
    required this.processingTimeMs,
    this.error,
  });

  factory ProcessedText.error(String originalText, String error) {
    return ProcessedText(
      originalText: originalText,
      cleanedText: '',
      tokens: [],
      features: {},
      spamIndicators: [],
      processingTimeMs: 0,
      error: error,
    );
  }

  bool get hasError => error != null;

  double get spamScore {
    if (spamIndicators.isEmpty) return 0.0;
    return spamIndicators
            .map((indicator) => indicator.confidence)
            .reduce((a, b) => a + b) /
        spamIndicators.length;
  }

  @override
  String toString() {
    return 'ProcessedText(tokens: ${tokens.length}, indicators: ${spamIndicators.length}, score: ${spamScore.toStringAsFixed(2)})';
  }
}

/// Represents a detected spam indicator
class SpamIndicator {
  final SpamIndicatorType type;
  final String matchedText;
  final double confidence;
  final int position;

  const SpamIndicator({
    required this.type,
    required this.matchedText,
    required this.confidence,
    required this.position,
  });

  @override
  String toString() {
    return 'SpamIndicator(type: $type, text: "$matchedText", confidence: ${confidence.toStringAsFixed(2)})';
  }
}

/// Types of spam indicators
enum SpamIndicatorType {
  financial,
  urgency,
  contact,
  promotional,
  excessiveCaps,
  excessiveNumbers,
  general,
}
