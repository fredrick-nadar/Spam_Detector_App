// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classification_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassificationResult _$ClassificationResultFromJson(
  Map<String, dynamic> json,
) => ClassificationResult(
  smsId: json['smsId'] as String,
  classification: json['classification'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  detectedKeywords: (json['detectedKeywords'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  classifiedAt: DateTime.parse(json['classifiedAt'] as String),
  modelVersion: json['modelVersion'] as String,
);

Map<String, dynamic> _$ClassificationResultToJson(
  ClassificationResult instance,
) => <String, dynamic>{
  'smsId': instance.smsId,
  'classification': instance.classification,
  'confidence': instance.confidence,
  'detectedKeywords': instance.detectedKeywords,
  'classifiedAt': instance.classifiedAt.toIso8601String(),
  'modelVersion': instance.modelVersion,
};
