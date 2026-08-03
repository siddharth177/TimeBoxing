import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/goal_provider.dart';
import '../widgets/goal_form_widgets.dart';
import '../widgets/goal_list_widgets.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: GoalTier.values.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  GoalTier get _tier => GoalTier.values[_tab.index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Goals', style: AppTextStyles.heading2xl()),
                  const SizedBox(height: 16),
                  TierTabStrip(controller: _tab),
                ],
              ), // Column
            ), // Padding
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: GoalTier.values
                    .map(
                      (t) => GoalPage(
                        tier: t,
                        onAdd: (parentId) => GoalSheets.showAdd(
                          context,
                          ref,
                          t,
                          parentId: parentId,
                        ),
                        onEdit: (goal) =>
                            GoalSheets.showEdit(context, ref, t, goal),
                      ),
                    ) // GoalPage
                    .toList(),
              ), // TabBarView
            ), // Expanded
          ],
        ), // Column
      ), // SafeArea
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-goals',
        onPressed: () => GoalSheets.showAdd(context, ref, _tier),
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Add Goal', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.green60,
      ), // FloatingActionButton.extended
    ); // Scaffold
  }
}
