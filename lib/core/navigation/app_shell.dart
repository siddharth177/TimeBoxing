import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/notification_service.dart';

/// Global provider for the selected shell tab index.
/// Any screen can read/write this to programmatically switch tabs.
final shellTabProvider = StateProvider<int>((ref) => 2);

const _destinations = <(IconData, IconData, String)>[
  (Icons.flag_outlined, Icons.flag_rounded, 'Goals'),
  (Icons.view_timeline_outlined, Icons.view_timeline, 'Timebox'),
  (Icons.home_outlined, Icons.home_rounded, 'Focus'),
  (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Review'),
  (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
];

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(shellTabProvider));
    _scheduleNotifications(ref.read(currentStreakProvider));
  }

  Future<void> _scheduleNotifications(int streak) async {
    await NotificationService.scheduleStreakWarning(streak: streak);
    await NotificationService.scheduleWeeklyDigest();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    // Only update the provider; ref.listen handles animation.
    ref.read(shellTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(shellTabProvider);
    final isWide = MediaQuery.of(context).size.width >= 600;

    ref.listen<int>(currentStreakProvider, (prev, next) {
      if (prev != next) NotificationService.scheduleStreakWarning(streak: next);
    });

    ref.listen<int>(shellTabProvider, (_, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    final pageView = PageView(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (i) => ref.read(shellTabProvider.notifier).state = i,
      children: const [
        GoalsScreen(),
        TimeboxingScreen(),
        FocusScreen(),
        ReviewScreen(),
        SettingsScreen(),
      ],
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: tab,
              onDestinationSelected: _onNavTap,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (unsel, sel, label) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(unsel),
                    selectedIcon: Icon(sel),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: pageView),
          ],
        ),
      );
    }

    return Scaffold(
      body: pageView,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: _onNavTap,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final (unsel, sel, label) in _destinations)
            NavigationDestination(
              icon: Icon(unsel),
              selectedIcon: Icon(sel),
              label: label,
            ),
        ],
      ),
    );
  }
}
