import 'package:json_annotation/json_annotation.dart';

part 'classification_result.g.dart';

@JsonSerializable()
class ClassificationResult {
  final String smsId;
  final String classification; // 'spam' or 'ham'
  final double confidence;
  final List<String> detectedKeywords;
  final DateTime classifiedAt;
  final String modelVersion;

  const ClassificationResult({
    required this.smsId,
    required this.classification,
    required this.confidence,
    required this.detectedKeywords,
    required this.classifiedAt,
    required this.modelVersion,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json) =>
      _$ClassificationResultFromJson(json);

  Map<String, dynamic> toJson() => _$ClassificationResultToJson(this);

  bool get isSpam => classification.toLowerCase() == 'spam';
  bool get isHam => classification.toLowerCase() == 'ham';

  @override
  String toString() {
    return 'ClassificationResult(smsId: $smsId, classification: $classification, '
        'confidence: $confidence, keywords: $detectedKeywords)';
  }
}
