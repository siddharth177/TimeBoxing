import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../services/notification_service.dart';
import '../models/daily_log.dart';
import '../models/insight.dart';

// FIREBASE CONSOLE SETUP (one-time):
//   1. Firebase Console → your project → Build → AI Logic
//   2. Enable "Google AI" provider (free tier available)
//   3. Add the `firebase_ai` package (already done in pubspec.yaml)
// The service is no-op on web builds (no notification support) and silently
// swallows errors so it never disrupts the save flow.

class ReflectionAnalysisService {
  ReflectionAnalysisService(this._uid);

  final String _uid;
  static const _uuid = Uuid();
  static const _minLogs = 7;
  static const _minDaysBetweenAnalyses = 7;

  static final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash',
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.2,
    ),
  );

  CollectionReference<Map<String, dynamic>> get _insightsCol =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('insights');

  CollectionReference<Map<String, dynamic>> get _logsCol => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('dailyLogs');

  /// [knownLogCount] short-circuits the Firestore log count read when already
  /// known from the cached provider (avoids an unnecessary round-trip).
  Future<bool> shouldAnalyze([int? knownLogCount]) async {
    try {
      if (knownLogCount != null) {
        if (knownLogCount < _minLogs) return false;
      } else {
        final logsSnap = await _logsCol
            .orderBy('date', descending: true)
            .limit(_minLogs)
            .get();
        if (logsSnap.docs.length < _minLogs) return false;
      }

      final lastSnap = await _insightsCol
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (lastSnap.docs.isEmpty) return true;

      final lastAt = (lastSnap.docs.first.data()['createdAt'] as Timestamp)
          .toDate();
      return DateTime.now().difference(lastAt).inDays >=
          _minDaysBetweenAnalyses;
    } catch (_) {
      return false;
    }
  }

  Future<void> forceAnalyze(List<DailyLog> logs, {List<String>? goalTitles}) =>
      _runAnalysis(logs, goalTitles: goalTitles);

  Future<void> analyze(List<DailyLog> logs, {List<String>? goalTitles}) async {
    if (logs.length < _minLogs) return;
    return _runAnalysis(logs, goalTitles: goalTitles);
  }

  Future<void> _runAnalysis(
    List<DailyLog> logs, {
    List<String>? goalTitles,
  }) async {
    final logData = logs.map((l) {
      final dow = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][l.date.weekday - 1];
      return {
        'date': l.dateKey,
        'dayOfWeek': dow,
        'priorities': {'total': l.totalTasks, 'completed': l.completedTasks},
        'chores': {'total': l.totalChores, 'completed': l.completedChores},
        'completionPct': (l.completionRate * 100).round(),
        'reflection': l.reflection ?? '',
        if (l.mood != null) 'mood': l.mood,
      };
    }).toList();

    final goalsSection = (goalTitles != null && goalTitles.isNotEmpty)
        ? "\nUser's active long-term goals: ${goalTitles.map((t) => '"$t"').join(', ')}\n"
        : '';

    final prompt =
        '''
You are a supportive productivity coach analyzing a user's daily timeboxing logs.
$goalsSection
Here are their last ${logs.length} daily logs (most recent first):
${jsonEncode(logData)}

Analyze this data and identify 2-3 specific, honest patterns. Consider these signals:

1. Over-commitment (type: "overcommitting"): completion rate consistently below 60%
2. Chore-heavy (type: "choreHeavy"): chores get done but priorities don't
3. Burnout (type: "burnout"): completion rate declining over consecutive days
4. Day-of-week weakness (type: "dayPattern"): specific days with consistently lower performance
5. Reflection themes (type: "reflectionPattern"): words that repeat across reflection 
    notes
6. Priority/time management (type: "timeManagement"): high-priority work consistently deferred or skipped while chores are completed

Be specific — reference actual numbers (e.g. "You completed priorities only 2/7 days").
If goal titles are provided, mention if any patterns suggest risk to a specific goal.
Keep tone supportive and actionable, not judgmental.

Return ONLY valid JSON:
{
  "headline": "One concise sentence (max 15 words) naming the single most important finding",
  "insights": [
    {
      "type": "overcommitting|choreHeavy|dayPattern|burnout|timeManagement|reflectionPattern",
      "title": "4-6 word title",
      "detail": "1-2 sentences with specific data points from the logs",
      "suggestion": "One concrete, actionable change they can make tomorrow"
    }
  ]
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) return;

      final parsed = jsonDecode(text.trim()) as Map<String, dynamic>;
      final headline = parsed['headline'] as String? ?? '';
      if (headline.isEmpty) return;

      final items = ((parsed['insights'] as List<dynamic>?) ?? [])
          .map((i) => InsightItem.fromMap(i as Map<String, dynamic>))
          .toList();

      final insight = Insight(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        headline: headline,
        items: items,
        logsAnalyzed: logs.length,
      );

      await _insightsCol.doc(insight.id).set(insight.toMap());

      await NotificationService.showNow(
        id: NotificationIds.insightReady,
        title: '💡 TimeBox Insight',
        body: headline,
      );
    } catch (e, st) {
      debugPrint('[ReflectionAnalysis] Error: $e\n$st');
    }
  }
}
