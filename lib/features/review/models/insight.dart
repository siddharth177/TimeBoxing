import 'package:cloud_firestore/cloud_firestore.dart';

enum InsightType {
  overcommitting,
  choreHeavy,
  dayPattern,
  burnout,
  timeManagement,
  reflectionPattern,
}

class InsightItem {
  const InsightItem({
    required this.type,
    required this.title,
    required this.detail,
    required this.suggestion,
  });

  final InsightType type;
  final String title;
  final String detail;
  final String suggestion;

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'title': title,
    'detail': detail,
    'suggestion': suggestion,
  };

  factory InsightItem.fromMap(Map<String, dynamic> m) => InsightItem(
    type: InsightType.values.firstWhere(
      (e) => e.name == (m['type'] as String? ?? ''),
      orElse: () => InsightType.overcommitting,
    ),
    title: m['title'] as String? ?? '',
    detail: m['detail'] as String? ?? '',
    suggestion: m['suggestion'] as String? ?? '',
  );
}

class Insight {
  const Insight({
    required this.id,
    required this.createdAt,
    required this.headline,
    required this.items,
    required this.logsAnalyzed,
  });

  final String id;
  final DateTime createdAt;
  final String headline;
  final List<InsightItem> items;
  final int logsAnalyzed;

  Map<String, dynamic> toMap() => {
    'createdAt': Timestamp.fromDate(createdAt),
    'headline': headline,
    'items': items.map((i) => i.toMap()).toList(),
    'logsAnalyzed': logsAnalyzed,
  };

  factory Insight.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Insight(
      id: doc.id,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      headline: d['headline'] as String? ?? '',
      items: ((d['items'] as List<dynamic>?) ?? [])
          .map((i) => InsightItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      logsAnalyzed: d['logsAnalyzed'] as int? ?? 0,
    );
  }
}
