import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/circular_day_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(appSettingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text('Settings', style: AppTextStyles.heading2xl()),
            const SizedBox(height: 28),

            _SectionLabel(
              'Appearance',
              scheme,
              tooltip: 'Switch between light, dark, or system-matched theme.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.auto_mode_outlined),
                  label: Text('Auto'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (v) =>
                  ref.read(themeModeProvider.notifier).set(v.first),
            ),
            const SizedBox(height: 32),

            _SectionLabel(
              'Day Boundaries',
              scheme,
              tooltip:
                  'Your active window — tasks and timeline blocks are scoped to these hours.',
            ),
            const SizedBox(height: 4),
            Center(
              child: CircularDayPicker(
                startHour: settings.dayStartHour,
                endHour: settings.dayEndHour,
                onStartChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .update(settings.copyWith(dayStartHour: v)),
                onEndChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .update(settings.copyWith(dayEndHour: v)),
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel(
              'Block Snapping',
              scheme,
              tooltip: 'Granularity when dragging time blocks on the timeline.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 min')),
                ButtonSegment(value: 30, label: Text('30 min')),
                ButtonSegment(value: 60, label: Text('1 hour')),
              ],
              selected: {settings.snapMinutes},
              onSelectionChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(snapMinutes: v.first)),
            ),
            const SizedBox(height: 32),

            _SectionLabel(
              'Task Limits',
              scheme,
              tooltip:
                  'Cap the number of tasks you can add per day to keep your list realistic.',
            ),
            const SizedBox(height: 12),
            _CountStepper(
              label: 'Max priorities per day',
              tooltip:
                  'High-focus tasks (P1–P5). Keep this low — 1–3 is ideal.',
              value: settings.maxPriorities,
              min: 1,
              max: 5,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(maxPriorities: v)),
            ),
            const SizedBox(height: 12),
            _CountStepper(
              label: 'Max chores per day',
              tooltip:
                  'Recurring or maintenance tasks. More forgiving than priorities.',
              value: settings.maxChores,
              min: 1,
              max: 10,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(maxChores: v)),
            ),
            const SizedBox(height: 32),

            _SectionLabel(
              'Task Colours',
              scheme,
              tooltip:
                  'Colour-code task slots so each block is visually distinct on the timeline.',
            ),
            const SizedBox(height: 12),
            _ColorSection(
              sectionLabel: 'Priorities',
              slotPrefix: 'P',
              slotCount: settings.maxPriorities,
              colors: settings.priorityColors,
              perSlot: settings.prioritiesPerSlot,
              defaultArgb: AppColors.brown60.toARGB32(),
              onPerSlotChanged: (v) {
                var cols = settings.priorityColors;
                if (v && cols.length <= 1) {
                  final base = cols.isEmpty
                      ? AppColors.brown60.toARGB32()
                      : cols[0];
                  cols = List.filled(settings.maxPriorities, base);
                }
                ref
                    .read(appSettingsProvider.notifier)
                    .update(
                      settings.copyWith(
                        prioritiesPerSlot: v,
                        priorityColors: cols,
                      ),
                    );
              },
              onColorChanged: (index, color) {
                final updated = _updatedColors(
                  current: settings.priorityColors,
                  index: index,
                  color: color,
                  count: settings.prioritiesPerSlot
                      ? settings.maxPriorities
                      : 1,
                  defaultArgb: AppColors.brown60.toARGB32(),
                );
                ref
                    .read(appSettingsProvider.notifier)
                    .update(settings.copyWith(priorityColors: updated));
              },
            ),
            const SizedBox(height: 16),
            _ColorSection(
              sectionLabel: 'Chores',
              slotPrefix: 'C',
              slotCount: settings.maxChores,
              colors: settings.choreColors,
              perSlot: settings.choresPerSlot,
              defaultArgb: AppColors.orange40.toARGB32(),
              onPerSlotChanged: (v) {
                var cols = settings.choreColors;
                if (v && cols.length <= 1) {
                  final base = cols.isEmpty
                      ? AppColors.orange40.toARGB32()
                      : cols[0];
                  cols = List.filled(settings.maxChores, base);
                }
                ref
                    .read(appSettingsProvider.notifier)
                    .update(
                      settings.copyWith(choresPerSlot: v, choreColors: cols),
                    );
              },
              onColorChanged: (index, color) {
                final updated = _updatedColors(
                  current: settings.choreColors,
                  index: index,
                  color: color,
                  count: settings.choresPerSlot ? settings.maxChores : 1,
                  defaultArgb: AppColors.orange40.toARGB32(),
                );
                ref
                    .read(appSettingsProvider.notifier)
                    .update(settings.copyWith(choreColors: updated));
              },
            ),
            const SizedBox(height: 32),

            _SectionLabel(
              'Notifications',
              scheme,
              tooltip: 'Controls push alerts for your scheduled time blocks.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Block reminders', style: AppTextStyles.textMd()),
              subtitle: Text(
                'Alert when a new time block starts',
                style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
              ),
              value: settings.notificationsEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(notificationsEnabled: v)),
            ),
            const SizedBox(height: 32),

            _SectionLabel(
              'Content',
              scheme,
              tooltip:
                  'Show or hide optional description fields across the app.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Show descriptions', style: AppTextStyles.textMd()),
              subtitle: Text(
                'Add optional descriptions to goals, tasks, and time blocks',
                style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
              ),
              value: settings.showDescriptions,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(showDescriptions: v)),
            ),
            const SizedBox(height: 32),

            _SectionLabel('About', scheme),
            const SizedBox(height: 8),
            _AboutRow(
              icon: Icons.info_outline,
              label: 'Version',
              value: '0.1.0',
            ),
            _AboutRow(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              value: '',
              onTap: () {},
            ),
            _AboutRow(
              icon: Icons.mail_outline,
              label: 'Send Feedback',
              value: '',
              onTap: () => launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: 'siddharth.dev177@gmail.com',
                  queryParameters: {'subject': 'Timebox Feedback'},
                ),
              ),
            ),
            const SizedBox(height: 32),

            _SectionLabel('Account', scheme),
            const SizedBox(height: 8),
            if (firebaseReady)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.orange40),
                title: Text(
                  'Sign out',
                  style: AppTextStyles.textMd(color: AppColors.orange40),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text(
                        'You will need to sign back in to access your data.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange40,
                          ),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await FirebaseAuth.instance.signOut();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

List<int> _updatedColors({
  required List<int> current,
  required int index,
  required Color color,
  required int count,
  required int defaultArgb,
}) {
  final result = List<int>.generate(
    count,
    (i) => (i < current.length) ? current[i] : defaultArgb,
  );
  if (index < result.length) result[index] = color.toARGB32();
  return result;
}

class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.sectionLabel,
    required this.slotPrefix,
    required this.slotCount,
    required this.colors,
    required this.perSlot,
    required this.defaultArgb,
    required this.onPerSlotChanged,
    required this.onColorChanged,
  });

  final String sectionLabel;
  final String slotPrefix;
  final int slotCount;
  final List<int> colors;
  final bool perSlot;
  final int defaultArgb;
  final ValueChanged<bool> onPerSlotChanged;
  final void Function(int index, Color color) onColorChanged;

  Color _colorAt(int index) {
    if (!perSlot) return colors.isEmpty ? Color(defaultArgb) : Color(colors[0]);
    if (index < colors.length) return Color(colors[index]);
    return Color(defaultArgb);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(sectionLabel, style: AppTextStyles.textMd())),
            SegmentedButton<bool>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: false, label: Text('All same')),
                ButtonSegment(value: true, label: Text('Per slot')),
              ],
              selected: {perSlot},
              onSelectionChanged: (v) => onPerSlotChanged(v.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!perSlot)
          _SwatchRow(selected: _colorAt(0), onPick: (c) => onColorChanged(0, c))
        else
          for (var i = 0; i < slotCount; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$slotPrefix${i + 1}',
                    style: AppTextStyles.textSm(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                _SwatchRow(
                  selected: _colorAt(i),
                  onPick: (c) => onColorChanged(i, c),
                ),
              ],
            ),
          ],
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.selected, required this.onPick});

  final Color selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final argb in kTaskColorSwatches)
          GestureDetector(
            onTap: () => onPick(Color(argb)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(argb),
                shape: BoxShape.circle,
                border: Color(argb) == selected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: Color(argb) == selected
                    ? [
                        BoxShadow(
                          color: Color(argb).withValues(alpha: 0.55),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.scheme, {this.tooltip});

  final String label;
  final ColorScheme scheme;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTextStyles.headingXs(color: scheme.onSurfaceVariant),
    );
    if (tooltip == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        const SizedBox(width: 6),
        Tooltip(
          message: tooltip!,
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: true,
          child: Icon(
            Icons.info_outline,
            size: 14,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.tooltip,
  });

  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDec = value > min;
    final canInc = value < max;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(label, style: AppTextStyles.textMd()),
              if (tooltip != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: tooltip!,
                  triggerMode: TooltipTriggerMode.tap,
                  preferBelow: true,
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
        _StepBtn(
          icon: Icons.remove,
          enabled: canDec,
          onTap: canDec ? () => onChanged(value - 1) : null,
          scheme: scheme,
        ),
        SizedBox(
          width: 40,
          child: Center(
            child: Text(
              '$value',
              style: AppTextStyles.headingXs(color: scheme.primary),
            ),
          ),
        ),
        _StepBtn(
          icon: Icons.add,
          enabled: canInc,
          onTap: canInc ? () => onChanged(value + 1) : null,
          scheme: scheme,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? scheme.outlineVariant
                : scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? scheme.onSurface : scheme.outlineVariant,
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label, style: AppTextStyles.textMd()),
      trailing: value.isNotEmpty
          ? Text(
              value,
              style: AppTextStyles.textMd(color: scheme.onSurfaceVariant),
            )
          : onTap != null
          ? Icon(Icons.chevron_right, color: scheme.outlineVariant)
          : null,
      onTap: onTap,
    );
  }
}
