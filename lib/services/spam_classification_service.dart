import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/sms_message.dart';
import '../models/classification_result.dart';
import 'nlp_preprocessing_service.dart';

/// Spam classification engine using a combination of rule-based and ML approaches
class SpamClassificationService {
  static final SpamClassificationService _instance =
      SpamClassificationService._internal();
  factory SpamClassificationService() => _instance;
  SpamClassificationService._internal();

  final Logger _logger = Logger();
  final NlpPreprocessingService _preprocessor = NlpPreprocessingService();

  // Model configuration
  static const String _modelVersion = '1.0.0';
  static const double _defaultSpamThreshold =
      0.5; // Lowered for better detection

  // Keyword weights and spam keywords
  Map<String, double> _spamKeywords = {};
  Map<String, double> _hamKeywords = {};

  // Feature weights for the classifier
  final Map<String, double> _featureWeights = {
    'length': 0.1,
    'word_count': 0.15,
    'avg_word_length': 0.05,
    'uppercase_ratio': 0.2,
    'digit_ratio': 0.15,
    'special_char_ratio': 0.1,
    'exclamation_count': 0.1,
    'question_count': 0.05,
    'dollar_sign_count': 0.15,
    'url_count': 0.3,
    'phone_pattern_count': 0.2,
  };

  bool _isInitialized = false;

  /// Initialize the classification service
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing spam classification service...');

      await _loadSpamKeywords();
      await _loadHamKeywords();

      _isInitialized = true;
      _logger.i('Spam classification service initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize spam classification service',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Classify an SMS message as spam or ham
  Future<ClassificationResult> classifyMessage(SmsMessage smsMessage) async {
    if (!_isInitialized) {
      throw StateError(
        'Classification service not initialized. Call initialize() first.',
      );
    }

    try {
      _logger.d('Classifying message: ${smsMessage.id}');

      final stopwatch = Stopwatch()..start();

      // Preprocess the text
      final processedText = await _preprocessor.preprocessText(smsMessage.body);

      // Calculate various scores
      final keywordScore = _calculateKeywordScore(processedText);
      final featureScore = _calculateFeatureScore(processedText.features);
      final indicatorScore = _calculateIndicatorScore(
        processedText.spamIndicators,
      );

      // Combine scores using weighted average
      final combinedScore = _combineScores(
        keywordScore,
        featureScore,
        indicatorScore,
      );

      // Determine classification
      final classification = combinedScore >= _defaultSpamThreshold
          ? 'spam'
          : 'ham';

      // Extract detected keywords
      final detectedKeywords = _extractDetectedKeywords(processedText);

      stopwatch.stop();

      final result = ClassificationResult(
        smsId: smsMessage.id,
        classification: classification,
        confidence: combinedScore,
        detectedKeywords: detectedKeywords,
        classifiedAt: DateTime.now(),
        modelVersion: _modelVersion,
      );

      _logger.d(
        'Message ${smsMessage.id} classified as $classification (confidence: ${combinedScore.toStringAsFixed(3)}) in ${stopwatch.elapsedMilliseconds}ms',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to classify message ${smsMessage.id}',
        error: e,
        stackTrace: stackTrace,
      );

      // Return a low-confidence ham classification on error
      return ClassificationResult(
        smsId: smsMessage.id,
        classification: 'ham',
        confidence: 0.0,
        detectedKeywords: [],
        classifiedAt: DateTime.now(),
        modelVersion: _modelVersion,
      );
    }
  }

  /// Calculate keyword-based spam score
  double _calculateKeywordScore(ProcessedText processedText) {
    double spamScore = 0.0;
    double hamScore = 0.0;

    for (final token in processedText.tokens) {
      // Check spam keywords
      if (_spamKeywords.containsKey(token)) {
        spamScore += _spamKeywords[token]!;
      }

      // Check ham keywords
      if (_hamKeywords.containsKey(token)) {
        hamScore += _hamKeywords[token]!;
      }
    }

    // Normalize by text length
    final totalTokens = processedText.tokens.length;
    if (totalTokens > 0) {
      spamScore = spamScore / totalTokens;
      hamScore = hamScore / totalTokens;
    }

    // Return the difference, normalized to 0-1 range
    final score = (spamScore - hamScore).clamp(0.0, 1.0);

    _logger.d('Keyword score: $score (spam: $spamScore, ham: $hamScore)');
    return score;
  }

  /// Calculate feature-based spam score
  double _calculateFeatureScore(Map<String, double> features) {
    double score = 0.0;
    double totalWeight = 0.0;

    features.forEach((feature, value) {
      if (_featureWeights.containsKey(feature)) {
        final weight = _featureWeights[feature]!;

        // Normalize feature values to 0-1 range based on typical spam characteristics
        double normalizedValue = _normalizeFeatureValue(feature, value);

        score += normalizedValue * weight;
        totalWeight += weight;
      }
    });

    final finalScore = totalWeight > 0 ? score / totalWeight : 0.0;

    _logger.d('Feature score: $finalScore');
    return finalScore.clamp(0.0, 1.0);
  }

  /// Normalize feature values to 0-1 range
  double _normalizeFeatureValue(String feature, double value) {
    switch (feature) {
      case 'length':
        // Spam messages are often short and attention-grabbing
        return value > 160 ? 0.3 : (value < 50 ? 0.8 : 0.5);

      case 'word_count':
        // Similar to length
        return value > 30 ? 0.3 : (value < 10 ? 0.7 : 0.4);

      case 'uppercase_ratio':
        // High uppercase ratio is spammy
        return (value * 2).clamp(0.0, 1.0);

      case 'digit_ratio':
        // High digit ratio can indicate phone numbers, amounts, etc.
        return (value * 1.5).clamp(0.0, 1.0);

      case 'special_char_ratio':
        // Moderate special characters are spammy
        return value > 0.1 ? (value * 3).clamp(0.0, 1.0) : 0.0;

      case 'exclamation_count':
        // Multiple exclamations are spammy
        return value > 1 ? 0.8 : (value > 0 ? 0.4 : 0.0);

      case 'dollar_sign_count':
        // Any dollar signs are suspicious
        return value > 0 ? 0.9 : 0.0;

      case 'url_count':
        // URLs in SMS are very suspicious
        return value > 0 ? 1.0 : 0.0;

      case 'phone_pattern_count':
        // Phone patterns can be spammy
        return value > 1 ? 0.7 : (value > 0 ? 0.3 : 0.0);

      default:
        return value;
    }
  }

  /// Calculate spam indicator score
  double _calculateIndicatorScore(List<SpamIndicator> indicators) {
    if (indicators.isEmpty) return 0.0;

    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final indicator in indicators) {
      // Weight indicators by type
      double weight = _getIndicatorWeight(indicator.type);

      totalScore += indicator.confidence * weight;
      totalWeight += weight;
    }

    final finalScore = totalWeight > 0 ? totalScore / totalWeight : 0.0;

    _logger.d(
      'Indicator score: $finalScore from ${indicators.length} indicators',
    );
    return finalScore.clamp(0.0, 1.0);
  }

  /// Get weight for different indicator types
  double _getIndicatorWeight(SpamIndicatorType type) {
    switch (type) {
      case SpamIndicatorType.financial:
        return 1.0;
      case SpamIndicatorType.urgency:
        return 0.8;
      case SpamIndicatorType.contact:
        return 0.7;
      case SpamIndicatorType.promotional:
        return 0.6;
      case SpamIndicatorType.excessiveCaps:
        return 0.5;
      case SpamIndicatorType.excessiveNumbers:
        return 0.4;
      case SpamIndicatorType.general:
        return 0.3;
    }
  }

  /// Combine different scores into final classification score
  double _combineScores(
    double keywordScore,
    double featureScore,
    double indicatorScore,
  ) {
    // Weighted combination of scores
    const double keywordWeight = 0.4;
    const double featureWeight = 0.3;
    const double indicatorWeight = 0.3;

    final combinedScore =
        (keywordScore * keywordWeight) +
        (featureScore * featureWeight) +
        (indicatorScore * indicatorWeight);

    _logger.d(
      'Combined score: $combinedScore (keyword: $keywordScore, feature: $featureScore, indicator: $indicatorScore)',
    );

    return combinedScore.clamp(0.0, 1.0);
  }

  /// Extract keywords that were detected in the message
  List<String> _extractDetectedKeywords(ProcessedText processedText) {
    final detectedKeywords = <String>[];

    // Add tokens that match spam keywords
    for (final token in processedText.tokens) {
      if (_spamKeywords.containsKey(token)) {
        detectedKeywords.add(token);
      }
    }

    // Add matched text from spam indicators
    for (final indicator in processedText.spamIndicators) {
      if (indicator.matchedText.isNotEmpty &&
          !indicator.matchedText.contains('RATIO') &&
          !detectedKeywords.contains(indicator.matchedText.toLowerCase())) {
        detectedKeywords.add(indicator.matchedText.toLowerCase());
      }
    }

    return detectedKeywords;
  }

  /// Load spam keywords from storage or initialize with default set
  Future<void> _loadSpamKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spamKeywordsJson = prefs.getString('spam_keywords');

      if (spamKeywordsJson != null) {
        final decoded = json.decode(spamKeywordsJson) as Map<String, dynamic>;
        _spamKeywords = decoded.map(
          (key, value) => MapEntry(key, value.toDouble()),
        );
        _logger.d('Loaded ${_spamKeywords.length} spam keywords from storage');
      } else {
        _initializeDefaultSpamKeywords();
        await _saveSpamKeywords();
      }
    } catch (e) {
      _logger.w('Failed to load spam keywords, using defaults', error: e);
      _initializeDefaultSpamKeywords();
    }
  }

  /// Load ham (non-spam) keywords from storage or initialize with default set
  Future<void> _loadHamKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hamKeywordsJson = prefs.getString('ham_keywords');

      if (hamKeywordsJson != null) {
        final decoded = json.decode(hamKeywordsJson) as Map<String, dynamic>;
        _hamKeywords = decoded.map(
          (key, value) => MapEntry(key, value.toDouble()),
        );
        _logger.d('Loaded ${_hamKeywords.length} ham keywords from storage');
      } else {
        _initializeDefaultHamKeywords();
        await _saveHamKeywords();
      }
    } catch (e) {
      _logger.w('Failed to load ham keywords, using defaults', error: e);
      _initializeDefaultHamKeywords();
    }
  }

  /// Initialize default spam keywords
  void _initializeDefaultSpamKeywords() {
    _spamKeywords = {
      // Financial
      'free': 0.8,
      'win': 0.9,
      'winner': 0.9,
      'prize': 0.8,
      'cash': 0.7,
      'money': 0.6,
      'claim': 0.7,
      'reward': 0.6,
      'earn': 0.5,
      'income': 0.5,
      'investment': 0.6,
      'loan': 0.7,
      'credit': 0.6,
      'debt': 0.5,

      // Urgency
      'urgent': 0.8,
      'immediately': 0.7,
      'expire': 0.8,
      'expires': 0.8,
      'limited': 0.6,
      'offer': 0.5,
      'today': 0.4,
      'now': 0.5,
      'hurry': 0.7,
      'last': 0.4,
      'final': 0.5,

      // Contact
      'call': 0.6,
      'text': 0.4,
      'reply': 0.5,
      'send': 0.4,
      'contact': 0.5,
      'click': 0.6,
      'visit': 0.5,

      // Promotional
      'deal': 0.5,
      'discount': 0.6,
      'sale': 0.5,
      'promotion': 0.6,
      'special': 0.4,
      'exclusive': 0.6,

      // Suspicious
      'congratulations': 0.7,
      'selected': 0.6,
      'chosen': 0.6,
      'guaranteed': 0.8,
      'risk': 0.5,
      'opportunity': 0.5,
    };

    _logger.d('Initialized ${_spamKeywords.length} default spam keywords');
  }

  /// Initialize default ham keywords
  void _initializeDefaultHamKeywords() {
    _hamKeywords = {
      // Normal conversation
      'hello': 0.8,
      'thanks': 0.7,
      'please': 0.6,
      'meeting': 0.7,
      'schedule': 0.6,
      'appointment': 0.7,
      'family': 0.8,
      'friend': 0.7,
      'work': 0.6,
      'home': 0.7,
      'school': 0.6,
      'class': 0.6,
      'lunch': 0.7,
      'dinner': 0.7,
      'birthday': 0.8,
      'party': 0.6,
      'vacation': 0.7,
      'travel': 0.6,
      'love': 0.7,
      'miss': 0.6,
      'hope': 0.6,
      'good': 0.5,
      'great': 0.5,
      'awesome': 0.6,
      'wonderful': 0.6,
      'project': 0.6,
      'document': 0.6,
      'file': 0.5,
      'report': 0.6,
    };

    _logger.d('Initialized ${_hamKeywords.length} default ham keywords');
  }

  /// Save spam keywords to storage
  Future<void> _saveSpamKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_spamKeywords);
      await prefs.setString('spam_keywords', json);
    } catch (e) {
      _logger.e('Failed to save spam keywords', error: e);
    }
  }

  /// Save ham keywords to storage
  Future<void> _saveHamKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_hamKeywords);
      await prefs.setString('ham_keywords', json);
    } catch (e) {
      _logger.e('Failed to save ham keywords', error: e);
    }
  }

  /// Update spam keywords based on user feedback
  Future<void> updateKeywords(String text, bool isSpam) async {
    final processedText = await _preprocessor.preprocessText(text);

    for (final token in processedText.tokens) {
      if (isSpam) {
        _spamKeywords[token] = (_spamKeywords[token] ?? 0.0) + 0.1;
        _hamKeywords.remove(token); // Remove from ham if it exists
      } else {
        _hamKeywords[token] = (_hamKeywords[token] ?? 0.0) + 0.1;
        _spamKeywords.remove(token); // Remove from spam if it exists
      }
    }

    await _saveSpamKeywords();
    await _saveHamKeywords();

    _logger.d(
      'Updated keywords based on feedback for ${isSpam ? 'spam' : 'ham'} message',
    );
  }

  /// Get model statistics
  Map<String, dynamic> getModelStatistics() {
    return {
      'model_version': _modelVersion,
      'spam_keywords_count': _spamKeywords.length,
      'ham_keywords_count': _hamKeywords.length,
      'is_initialized': _isInitialized,
      'spam_threshold': _defaultSpamThreshold,
    };
  }

  /// Batch classify multiple messages
  Future<List<ClassificationResult>> batchClassify(
    List<SmsMessage> messages,
  ) async {
    _logger.i('Batch classifying ${messages.length} messages...');

    final results = <ClassificationResult>[];
    final stopwatch = Stopwatch()..start();

    for (final message in messages) {
      final result = await classifyMessage(message);
      results.add(result);
    }

    stopwatch.stop();
    _logger.i(
      'Batch classification completed in ${stopwatch.elapsedMilliseconds}ms',
    );

    return results;
  }
}
