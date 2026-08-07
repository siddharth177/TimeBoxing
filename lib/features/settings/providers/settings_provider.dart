import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../../core/providers/firebase_providers.dart";
import "../../../core/theme/app_colors.dart";

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    Future(_load);
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key);
    state = switch (val) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

/// Shared swatch list (ARGB ints) used in Settings and task rendering.
/// Values are derived from AppColors so the palette stays in sync.
final kTaskColorSwatches = <int>[
  AppColors.brown60.toARGB32(), // priority default
  AppColors.green60.toARGB32(), // olive green
  AppColors.orange40.toARGB32(), // chore default
  AppColors.purple60.toARGB32(), // purple
  AppColors.yellow40.toARGB32(), // yellow
  AppColors.gray40.toARGB32(), // grey
  AppColors.blue60.toARGB32(), // blue
  AppColors.pink60.toARGB32(), // pink
];

class AppSettings {
  const AppSettings({
    this.maxPriorities = 3,
    this.maxChores = 5,
    this.dayStartHour = 6,
    this.dayEndHour = 22,
    this.snapMinutes = 30,
    this.notificationsEnabled = true,
    this.showDescriptions = false,
    this.priorityColors = const [],
    this.prioritiesPerSlot = false,
    this.choreColors = const [],
    this.choresPerSlot = false,
    this.calendarSyncEnabled = false,
  });

  final int maxPriorities;
  final int maxChores;
  final int dayStartHour;
  final int dayEndHour;
  final int snapMinutes;
  final bool notificationsEnabled;
  final bool showDescriptions;

  /// Per-slot ARGB colours for priorities. Empty = use app default.
  final List<int> priorityColors;

  /// When false, priorityColors[0] applies to all slots.
  final bool prioritiesPerSlot;

  /// Per-slot ARGB colours for chores. Empty = use app default.
  final List<int> choreColors;

  /// When false, choreColors[0] applies to all slots.
  final bool choresPerSlot;
  final bool calendarSyncEnabled;

  Color colorForPriority(int slotIndex) {
    if (priorityColors.isEmpty) return const Color(0xFF926247);
    if (!prioritiesPerSlot) return Color(priorityColors[0]);
    if (slotIndex < priorityColors.length) {
      return Color(priorityColors[slotIndex]);
    }
    return const Color(0xFF926247);
  }

  Color colorForChore(int slotIndex) {
    if (choreColors.isEmpty) return const Color(0xFFED7E1C);
    if (!choresPerSlot) return Color(choreColors[0]);
    if (slotIndex < choreColors.length) return Color(choreColors[slotIndex]);
    return const Color(0xFFED7E1C);
  }

  Map<String, dynamic> toMap() => {
    'maxPriorities': maxPriorities,
    'maxChores': maxChores,
    'dayStartHour': dayStartHour,
    'dayEndHour': dayEndHour,
    'snapMinutes': snapMinutes,
    'notificationsEnabled': notificationsEnabled,
    'showDescriptions': showDescriptions,
    'priorityColors': priorityColors,
    'prioritiesPerSlot': prioritiesPerSlot,
    'choreColors': choreColors,
    'choresPerSlot': choresPerSlot,
  };

  factory AppSettings.fromMap(Map<String, dynamic> d) => AppSettings(
    maxPriorities: d['maxPriorities'] as int? ?? 3,
    maxChores: d['maxChores'] as int? ?? 5,
    dayStartHour: d['dayStartHour'] as int? ?? 6,
    dayEndHour: d['dayEndHour'] as int? ?? 22,
    snapMinutes: d['snapMinutes'] as int? ?? 30,
    notificationsEnabled: d['notificationsEnabled'] as bool? ?? true,
    showDescriptions: d['showDescriptions'] as bool? ?? false,
    priorityColors:
        (d['priorityColors'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [],
    prioritiesPerSlot: d['prioritiesPerSlot'] as bool? ?? false,
    choreColors:
        (d['choreColors'] as List?)?.map((e) => (e as num).toInt()).toList() ??
        [],
    choresPerSlot: d['choresPerSlot'] as bool? ?? false,
    calendarSyncEnabled: d['calendarSyncEnabled'] as bool? ?? false,
  );

  AppSettings copyWith({
    int? maxPriorities,
    int? maxChores,
    int? dayStartHour,
    int? dayEndHour,
    int? snapMinutes,
    bool? notificationsEnabled,
    bool? showDescriptions,
    List<int>? priorityColors,
    bool? prioritiesPerSlot,
    List<int>? choreColors,
    bool? choresPerSlot,
    bool? calendarSyncEnabled,
  }) => AppSettings(
    maxPriorities: maxPriorities ?? this.maxPriorities,
    maxChores: maxChores ?? this.maxChores,
    dayStartHour: dayStartHour ?? this.dayStartHour,
    dayEndHour: dayEndHour ?? this.dayEndHour,
    snapMinutes: snapMinutes ?? this.snapMinutes,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    showDescriptions: showDescriptions ?? this.showDescriptions,
    priorityColors: priorityColors ?? this.priorityColors,
    prioritiesPerSlot: prioritiesPerSlot ?? this.prioritiesPerSlot,
    choreColors: choreColors ?? this.choreColors,
    choresPerSlot: choresPerSlot ?? this.choresPerSlot,
    calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
  );
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final prevUid = prev?.value?.uid;
      final nextUid = next.value?.uid;
      if (nextUid != null && nextUid != prevUid) {
        _load(uid: nextUid);
      } else if (nextUid == null) {
        state = const AppSettings();
      }
    });
    Future(_load);
    return const AppSettings();
  }

  DocumentReference<Map<String, dynamic>>? _docFor(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('app');

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = ref.read(currentUserProvider)?.uid;
    return uid == null ? null : _docFor(uid);
  }

  Future<void> _load({String? uid}) async {
    final doc = uid != null ? _docFor(uid) : _doc;
    try {
      final snap = await doc?.get();
      if (snap != null && snap.exists && snap.data() != null) {
        state = AppSettings.fromMap(snap.data()!);
      }
    } catch (_) {}
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    try {
      await _doc?.set(settings.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }
}
