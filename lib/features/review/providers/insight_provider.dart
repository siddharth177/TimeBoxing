import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../models/insight.dart';
import '../services/reflection_analysis_service.dart';

final insightsProvider = StreamProvider<List<Insight>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('insights')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((s) => s.docs.map((d) => Insight.fromDoc(d)).toList());
});

final reflectionAnalysisServiceProvider =
Provider<ReflectionAnalysisService?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ReflectionAnalysisService(user.uid);
});
