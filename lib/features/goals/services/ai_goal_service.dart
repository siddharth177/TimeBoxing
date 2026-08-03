import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/cupertino.dart';

import '../providers/goals_provider.dart';

class AiShortGoal {
  AiShortGoal({
    required this.title,
    this.type = GoalItemType.milestone,
    this.tasks = const [],
  });

  String title;
  GoalItemType type;
  List<String> tasks;
}

class AiMediumGoal {
  AiMediumGoal({required this.title, this.shortGoals = const []});

  String title;
  List<AiShortGoal> shortGoals;
}

class AiGoalPlan {
  AiGoalPlan({
    this.mediumGoals = const [],
    this.shortGoals = const [],
    this.tasks = const [],
  });

  /// Populated for long-term goal decomposition.
  final List<AiMediumGoal> mediumGoals;

  /// Populated for medium-term goal decomposition.
  final List<AiShortGoal> shortGoals;

  /// Populated for short-term goal decomposition.
  final List<String> tasks;
}

class AiGoalService {
  AiGoalService._();

  static final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash',
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.2,
    ),
  );

  /// Decomposes a goal into a structured plan.
  /// [tier] determines the depth: long → medium+short+tasks,
  ///   medium → short+tasks, short → tasks only.
  static Future<AiGoalPlan?> decompose({
    required String title,
    required String? description,
    required GoalTier tier,
    required String category,
  }) async {
    final prompt = _buildPrompt(
      title: title,
      description: description,
      tier: tier,
      category: category,
    );
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null || text.isEmpty) return null;
        return _parse(text, tier);
      } catch (e) {
        debugPrint('[AiGoalService] Attempt ${attempt + 1} failed: $e');
        if (attempt == 1) return null;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  static String _buildPrompt({
    required String title,
    required String? description,
    required GoalTier tier,
    required String category,
  }) {
    final desc = description?.isNotEmpty == true
        ? '\nDescription: $description'
        : '';

    final categoryRules = _categoryRules(category);

    return switch (tier) {
      GoalTier.long =>
        '''
You are a productivity planning assistant.
Break down this long-term goal into an actionable plan.

Goal: "$title"$desc
Category: $category

Return ONLY valid JSON in exactly this structure (2 medium-term goals, each with 2-3 short-term
{
  "medium_goals": [
    {
      "title": "string",
      "short_goals": [
        {
          "title": "string",
          "type": "milestone",
          "tasks": ["string", "string"]
        }
      ]
    }
  ]
}

Rules:
- medium_goals: 2 items, each achievable in 3-6 months
- short_goals: 2-3 per medium goal, each achievable in 1-3 months
- tasks: 2-3 concrete daily/weekly priorities per short goal
- Be specific, actionable, and directly tied to the goal
- type must be one of: goal, milestone, checkpoint
$categoryRules''',

      GoalTier.medium =>
        '''
You are a productivity planning assistant.
Break down this medium-term goal into milestones and tasks.

Goal: "$title"$desc
Category: $category

Return ONLY valid JSON in exactly this structure (3-4 short-term milestones,
each with 2-3 tasks):
{
  "short_goals": [
    {
      "title": "string",
      "type": "milestone",
      "tasks": ["string", "string"]
    }
  ]
}

Rules:
- short_goals: 3-4 milestones, each achievable in 2-6 weeks
- tasks: 2-3 concrete daily/weekly priority tasks per milestone
- type must be one of: goal, milestone, checkpoint
- Be specific and actionable
$categoryRules''',

      GoalTier.short =>
        '''
You are a productivity planning assistant.
Break down this short-term goal into priority tasks.

Goal: "$title"$desc
Category: $category

Return ONLY valid JSON in exactly this structure (4-6 priority tasks):
{
  "tasks": ["string", "string", "string"]
}

Rules:
- tasks: 4-6 concrete, daily/weekly priority tasks
- Each task should be completable in a single work session
- Be specific and actionable
$categoryRules''',
    };
  }

  static String _categoryRules(String category) {
    return switch (category.toLowerCase()) {
      'health' =>
        '- Health goals: prioritise habit-forming tasks (daily/weekly repeats), '
            'not one-offs\n'
            '- Focus on consistency and progressive overload, not volume',
      'learning' =>
        '- Learning goals: use spaced-repetition checkpoints (study → practice → apply)\n'
            '- Each task should represent one focused learning session',
      'work' || 'career' =>
        '- Work goals: tie tasks to deliverables or measurable outcomes\n'
            '- Include review, collaboration, and feedback steps',
      'finance' || 'financial' =>
        '- Finance goals: each task should have a clear monetary action or review step\n'
            '- Include tracking and accountability tasks',
      _ => '',
    };
  }

  static AiGoalPlan _parse(String json, GoalTier tier) {
    final data = jsonDecode(json) as Map<String, dynamic>;

    if (tier == GoalTier.long) {
      final mediums = (data['medium_goals'] as List? ?? []).map((m) {
        final shorts = (m['short_goals'] as List? ?? []).map((s) {
          return AiShortGoal(
            title: s['title'] as String? ?? '',
            type: _parseType(s['type'] as String?),
            tasks: (s['tasks'] as List? ?? []).cast<String>(),
          );
        }).toList();
        return AiMediumGoal(
          title: m['title'] as String? ?? '',
          shortGoals: shorts,
        );
      }).toList();
      return AiGoalPlan(mediumGoals: mediums);
    }

    if (tier == GoalTier.medium) {
      final shorts = (data['short_goals'] as List? ?? []).map((s) {
        return AiShortGoal(
          title: s['title'] as String? ?? '',
          type: _parseType(s['type'] as String?),
          tasks: (s['tasks'] as List? ?? []).cast<String>(),
        );
      }).toList();
      return AiGoalPlan(shortGoals: shorts);
    }

    final tasks = (data['tasks'] as List? ?? []).cast<String>();
    return AiGoalPlan(tasks: tasks);
  }

  static GoalItemType _parseType(String? raw) {
    return switch (raw) {
      'milestone' => GoalItemType.milestone,
      'checkpoint' => GoalItemType.checkpoint,
      _ => GoalItemType.goal,
    };
  }
}
