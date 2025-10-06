import 'package:logger/logger.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

/// Service for AI-powered spam keyword extraction using Google Gemini
class GeminiAiService {
  static final GeminiAiService _instance = GeminiAiService._internal();
  factory GeminiAiService() => _instance;
  GeminiAiService._internal();

  final Logger _logger = Logger();

  GenerativeModel? _model;
  String? _apiKey;
  bool _isInitialized = false;

  /// Initialize the Gemini AI service with API key
  Future<bool> initialize(String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        _logger.w('Gemini API key is empty');
        return false;
      }

      _logger.i('Initializing Gemini AI service...');
      _apiKey = apiKey;

      // Create the Gemini model
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for more consistent results
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      _isInitialized = true;
      _logger.i('Gemini AI service initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize Gemini AI service',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Extract spam keywords and indicators from SMS text using AI
  Future<Map<String, dynamic>> extractSpamKeywords(String smsText) async {
    if (!_isInitialized || _model == null) {
      _logger.w('Gemini AI service not initialized');
      return {
        'keywords': <String>[],
        'spam_probability': 0.0,
        'reasoning': 'AI service not initialized',
        'indicators': <String>[],
      };
    }

    try {
      _logger.d('Extracting spam keywords using Gemini AI...');

      final prompt = _buildSpamAnalysisPrompt(smsText);

      final response = await _model!.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        _logger.w('Gemini returned null response');
        return _getDefaultResponse();
      }

      // Parse the JSON response from Gemini
      final parsedResponse = _parseGeminiResponse(response.text!);

      _logger.i(
        'Gemini AI extracted ${parsedResponse['keywords'].length} keywords',
      );
      return parsedResponse;
    } catch (e, stackTrace) {
      _logger.e(
        'Error extracting spam keywords',
        error: e,
        stackTrace: stackTrace,
      );
      return _getDefaultResponse();
    }
  }

  /// Analyze spam probability of SMS text
  Future<double> analyzeSpamProbability(String smsText) async {
    final result = await extractSpamKeywords(smsText);
    return result['spam_probability'] as double;
  }

  /// Build the prompt for Gemini AI
  String _buildSpamAnalysisPrompt(String smsText) {
    return '''
Analyze the following SMS message and determine if it's spam. 
Provide a structured JSON response with:
1. spam_probability: A number between 0.0 and 1.0 (0 = definitely not spam, 1 = definitely spam)
2. keywords: An array of specific words/phrases that indicate spam (max 10)
3. indicators: An array of spam indicators found (e.g., "urgency", "monetary", "suspicious_link")
4. reasoning: Brief explanation (max 100 characters)

SMS Text: "$smsText"

Response format (JSON only, no markdown):
{
  "spam_probability": 0.85,
  "keywords": ["won", "claim", "urgent", "click here"],
  "indicators": ["urgency", "monetary", "suspicious_link"],
  "reasoning": "Contains urgent monetary offer with suspicious link"
}
''';
  }

  /// Parse Gemini's response text into structured data
  Map<String, dynamic> _parseGeminiResponse(String responseText) {
    try {
      // Remove markdown code blocks if present
      String cleanedText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Parse JSON
      final jsonData = json.decode(cleanedText) as Map<String, dynamic>;

      // Validate and structure the response
      return {
        'spam_probability': _ensureDouble(jsonData['spam_probability'] ?? 0.5),
        'keywords': _ensureStringList(jsonData['keywords'] ?? []),
        'indicators': _ensureStringList(jsonData['indicators'] ?? []),
        'reasoning':
            jsonData['reasoning']?.toString() ?? 'AI analysis completed',
      };
    } catch (e) {
      _logger.e('Error parsing Gemini response: $e');
      _logger.d('Raw response: $responseText');

      // Fallback: try to extract keywords manually
      return _extractKeywordsManually(responseText);
    }
  }

  /// Ensure value is a double
  double _ensureDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.5;
    return 0.5;
  }

  /// Ensure value is a list of strings
  List<String> _ensureStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Manually extract keywords if JSON parsing fails
  Map<String, dynamic> _extractKeywordsManually(String responseText) {
    final keywords = <String>[];
    final indicators = <String>[];

    // Common spam indicators to look for in the response
    final indicatorPatterns = {
      'urgency': ['urgent', 'hurry', 'act now', 'limited time'],
      'monetary': ['money', 'cash', 'dollar', 'prize', 'won', 'winner'],
      'suspicious_link': ['click', 'link', 'url', 'http'],
      'scam': ['verify', 'account', 'suspended', 'confirm'],
    };

    // Extract indicators
    responseText = responseText.toLowerCase();
    for (var entry in indicatorPatterns.entries) {
      for (var pattern in entry.value) {
        if (responseText.contains(pattern)) {
          indicators.add(entry.key);
          keywords.add(pattern);
          break;
        }
      }
    }

    // Estimate spam probability based on indicators found
    double spamProb = indicators.length / indicatorPatterns.length;
    spamProb = spamProb.clamp(0.0, 1.0);

    return {
      'spam_probability': spamProb,
      'keywords': keywords.take(10).toList(),
      'indicators': indicators,
      'reasoning': 'Manual extraction from AI response',
    };
  }

  /// Get default response when analysis fails
  Map<String, dynamic> _getDefaultResponse() {
    return {
      'keywords': <String>[],
      'spam_probability': 0.5,
      'reasoning': 'Analysis failed, using default values',
      'indicators': <String>[],
    };
  }

  /// Batch analyze multiple messages
  Future<List<Map<String, dynamic>>> analyzeBatch(List<String> messages) async {
    final results = <Map<String, dynamic>>[];

    for (var message in messages) {
      final result = await extractSpamKeywords(message);
      results.add(result);

      // Add delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }

  /// Check if service is initialized and ready
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _model = null;
    _isInitialized = false;
    _logger.i('Gemini AI service disposed');
  }
}
