import 'package:json_annotation/json_annotation.dart';

part 'spam_keyword.g.dart';

@JsonSerializable()
class SpamKeyword {
  final String id;
  final String keyword;
  final double weight;
  final int frequency;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final bool isActive;
  final KeywordCategory category;

  const SpamKeyword({
    required this.id,
    required this.keyword,
    required this.weight,
    required this.frequency,
    required this.firstSeen,
    required this.lastSeen,
    this.isActive = true,
    this.category = KeywordCategory.general,
  });

  factory SpamKeyword.fromJson(Map<String, dynamic> json) =>
      _$SpamKeywordFromJson(json);

  Map<String, dynamic> toJson() => _$SpamKeywordToJson(this);

  SpamKeyword copyWith({
    String? id,
    String? keyword,
    double? weight,
    int? frequency,
    DateTime? firstSeen,
    DateTime? lastSeen,
    bool? isActive,
    KeywordCategory? category,
  }) {
    return SpamKeyword(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      weight: weight ?? this.weight,
      frequency: frequency ?? this.frequency,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'SpamKeyword(keyword: $keyword, weight: $weight, '
        'frequency: $frequency, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpamKeyword && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum KeywordCategory {
  financial,
  promotional,
  phishing,
  adult,
  general,
  medical,
  lottery,
  dating,
  investment,
  loan,
}
