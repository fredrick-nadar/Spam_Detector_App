// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spam_keyword.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpamKeyword _$SpamKeywordFromJson(Map<String, dynamic> json) => SpamKeyword(
  id: json['id'] as String,
  keyword: json['keyword'] as String,
  weight: (json['weight'] as num).toDouble(),
  frequency: (json['frequency'] as num).toInt(),
  firstSeen: DateTime.parse(json['firstSeen'] as String),
  lastSeen: DateTime.parse(json['lastSeen'] as String),
  isActive: json['isActive'] as bool? ?? true,
  category:
      $enumDecodeNullable(_$KeywordCategoryEnumMap, json['category']) ??
      KeywordCategory.general,
);

Map<String, dynamic> _$SpamKeywordToJson(SpamKeyword instance) =>
    <String, dynamic>{
      'id': instance.id,
      'keyword': instance.keyword,
      'weight': instance.weight,
      'frequency': instance.frequency,
      'firstSeen': instance.firstSeen.toIso8601String(),
      'lastSeen': instance.lastSeen.toIso8601String(),
      'isActive': instance.isActive,
      'category': _$KeywordCategoryEnumMap[instance.category]!,
    };

const _$KeywordCategoryEnumMap = {
  KeywordCategory.financial: 'financial',
  KeywordCategory.promotional: 'promotional',
  KeywordCategory.phishing: 'phishing',
  KeywordCategory.adult: 'adult',
  KeywordCategory.general: 'general',
  KeywordCategory.medical: 'medical',
  KeywordCategory.lottery: 'lottery',
  KeywordCategory.dating: 'dating',
  KeywordCategory.investment: 'investment',
  KeywordCategory.loan: 'loan',
};
