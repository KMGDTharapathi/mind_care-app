import 'dart:async';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/local/notification_service.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';

const _kTeal = Color(0xFF5BA8A0);
const _kDark = Color(0xFF1A4A4A);

class DailyRemindersScreen extends StatefulWidget {
  const DailyRemindersScreen({super.key});

  @override
  State<DailyRemindersScreen> createState() => _DailyRemindersScreenState();
}

class _DailyRemindersScreenState extends State<DailyRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = LanguageProvider.of(context);
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1A1A)
          : const Color(0xFFF0F9F9),
      appBar: AppBar(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        title: Text(
          s.remindersTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.notifications_outlined),
              text: s.pushTab,
            ),
            Tab(
              icon: const Icon(Icons.calendar_month_outlined),
              text: s.calendarTab,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PushTab(isDark: isDark),
          _CalendarTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ── Push Notification Tab ─────────────────────────────────────────────────────

class _PushTab extends StatelessWidget {
  final bool isDark;
  const _PushTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero
            _HeroBanner(
              icon: Icons.notifications_active_rounded,
              title: s.pushRemindersTitle,
              subtitle: s.pushRemindersSubtitle,
            ),
            const SizedBox(height: 20),

            // Enable toggle
            _ReminderCard(
              isDark: isDark,
              child: Row(
                children: [
                  _IconCircle(
                    icon: state.notificationsEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    color: state.notificationsEnabled ? _kTeal : Colors.grey,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.dailyReminderToggle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : _kDark,
                          ),
                        ),
                        Text(
                          state.notificationsEnabled
                              ? '${s.activeLabel} — ${state.repeatLabel}'
                              : s.tapToEnable,
                          style: TextStyle(
                            fontSize: 13,
                            color: state.notificationsEnabled
                                ? _kTeal
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: state.notificationsEnabled,
                    activeColor: _kTeal,
                    onChanged: (v) => _toggle(context, cubit, v),
                  ),
                ],
              ),
            ),

            if (state.notificationsEnabled) ...[
              const SizedBox(height: 12),

              // Time picker
              _ReminderCard(
                isDark: isDark,
                onTap: () => _pickTime(context, cubit, state),
                child: Row(
                  children: [
                    const _IconCircle(
                      icon: Icons.access_time_rounded,
                      color: _kTeal,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.reminderTime,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : _kDark,
                            ),
                          ),
                          Text(
                            s.tapToChange,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Pill(label: _fmtTime(context, state), color: _kTeal),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Repeat days
              _ReminderCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _IconCircle(
                          icon: Icons.repeat_rounded,
                          color: Color(0xFF7986CB),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.repeatLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : _kDark,
                                ),
                              ),
                              Text(
                                state.repeatLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7986CB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DayPicker(
                      selected: state.repeatDays,
                      onChanged: (days) => cubit.setRepeatDays(days),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Custom message
              _ReminderCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _IconCircle(
                          icon: Icons.edit_note_rounded,
                          color: Color(0xFFFF8A65),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          s.reminderMessage,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : _kDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MessagePicker(
                      current: state.reminderMessage,
                      isDark: isDark,
                      presets: s.reminderPresets,
                      onChanged: (msg) => cubit.setReminderMessage(msg),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            _InfoNote(isDark: isDark, text: s.pushInfoNote),
          ],
        );
      },
    );
  }

  String _fmtTime(BuildContext context, SettingsState state) {
    final t = state.notificationTime ?? const TimeOfDay(hour: 9, minute: 0);
    return t.format(context);
  }

  Future<void> _toggle(
    BuildContext context,
    SettingsCubit cubit,
    bool enabled,
  ) async {
    if (!enabled) {
      await cubit.setNotificationsEnabled(false);
      return;
    }
    await cubit.setNotificationsEnabled(
      true,
      onShowExplanation: () => _permissionDialog(context),
    );
  }

  Future<bool> _permissionDialog(BuildContext context) async {
    final s = LanguageProvider.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: _kTeal,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(s.enableNotifications),
          ],
        ),
        content: Text(
          s.notificationExplanation,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.notNow),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kTeal),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.allow),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickTime(
    BuildContext context,
    SettingsCubit cubit,
    SettingsState state,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          state.notificationTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _kTeal),
        ),
        child: child!,
      ),
    );
    if (picked != null) await cubit.setNotificationTime(picked);
  }
}

// ── Calendar Tab ──────────────────────────────────────────────────────────────

class _CalendarTab extends StatefulWidget {
  final bool isDark;
  const _CalendarTab({required this.isDark});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _selectedTypeIndex = 0;
  int _selectedProviderIndex = 0;
  bool _isRecurring = false;

  static const _typeIcons = [
    Icons.favorite_border_rounded,
    Icons.air_rounded,
    Icons.self_improvement_outlined,
    Icons.edit_outlined,
    Icons.star_outline_rounded,
  ];
  static const _typeColors = [
    Color(0xFFE57373),
    Color(0xFF5BA8A0),
    Color(0xFF7986CB),
    Color(0xFFFF8A65),
    Color(0xFF78909C),
  ];

  static const _providerIcons = [
    Icons.calendar_month_rounded,
    Icons.apple,
    Icons.email_outlined,
    Icons.calendar_view_month_rounded,
    Icons.more_horiz_rounded,
  ];
  static const _providerColors = [
    Color(0xFF4285F4),
    Color(0xFF9E9E9E),
    Color(0xFF0072C6),
    Color(0xFF5BA8A0),
    Color(0xFF78909C),
  ];

  List<String> _typeLabels(s) => [
        s.typeMoodCheckin,
        s.typeBreathing,
        s.typeMeditation,
        s.typeJournal,
        s.typeCustom,
      ];

  List<String> _providerLabels(s) => [
        s.providerGoogle,
        s.providerApple,
        s.providerOutlook,
        s.providerSamsung,
        s.providerOther,
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final s = LanguageProvider.of(context);
    final typeLabels = _typeLabels(s);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _HeroBanner(
          icon: Icons.calendar_month_rounded,
          title: s.calendarReminderTitle,
          subtitle: s.calendarReminderSubtitle,
          gradientColors: const [Color(0xFF7986CB), Color(0xFF5C6BC0)],
        ),
        const SizedBox(height: 20),

        // Type selector
        _ReminderCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _IconCircle(
                    icon: Icons.category_outlined,
                    color: Color(0xFF7986CB),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    s.reminderType,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _kDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(typeLabels.length, (i) {
                  final label = typeLabels[i];
                  final isSelected = _selectedTypeIndex == i;
                  final color = _typeColors[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTypeIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _typeIcons[i],
                            size: 16,
                            color: isSelected ? color : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? color : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Calendar provider selector
        _ReminderCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _IconCircle(
                    icon: Icons.cloud_outlined,
                    color: Color(0xFF4285F4),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.calendarProviderLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : _kDark,
                          ),
                        ),
                        Text(
                          s.calendarProviderHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  _providerLabels(s).length,
                  (i) {
                    final label = _providerLabels(s)[i];
                    final isSelected = _selectedProviderIndex == i;
                    final color = _providerColors[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedProviderIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _providerIcons[i],
                            size: 16,
                            color: isSelected ? color : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Date picker
        _ReminderCard(
          isDark: isDark,
          onTap: () => _pickDate(context),
          child: Row(
            children: [
              const _IconCircle(
                icon: Icons.calendar_today_outlined,
                color: _kTeal,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.dateLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _kDark,
                      ),
                    ),
                    Text(
                      s.tapToChoose,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(label: _fmtDate(_selectedDate), color: _kTeal),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Time picker
        _ReminderCard(
          isDark: isDark,
          onTap: () => _pickTime(context),
          child: Row(
            children: [
              const _IconCircle(
                icon: Icons.access_time_rounded,
                color: Color(0xFFFF8A65),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.timeLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _kDark,
                      ),
                    ),
                    Text(
                      s.tapToChoose,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(
                label: _selectedTime.format(context),
                color: const Color(0xFFFF8A65),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Recurring toggle
        _ReminderCard(
          isDark: isDark,
          child: Row(
            children: [
              const _IconCircle(
                icon: Icons.repeat_rounded,
                color: Color(0xFF7986CB),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.recurringLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _kDark,
                      ),
                    ),
                    Text(
                      _isRecurring ? s.repeatsWeekly : s.oneTimeEvent,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isRecurring
                            ? const Color(0xFF7986CB)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isRecurring,
                activeColor: const Color(0xFF7986CB),
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Add to calendar button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _addToCalendar(typeLabels),
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(s.addToCalendarBtn),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7986CB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        _InfoNote(isDark: isDark, text: s.calendarInfoNote),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: const Color(0xFF7986CB)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: const Color(0xFFFF8A65)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _addToCalendar(List<String> typeLabels) async {
    final selectedType = typeLabels[_selectedTypeIndex];
    final s = LanguageProvider.of(context);
    final provider = _providerLabels(s)[_selectedProviderIndex];
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final end = start.add(const Duration(minutes: 30));

    final event = Event(
      title: 'MindCare — $selectedType',
      description:
          'Your MindCare wellness reminder: $selectedType.\n\nOpened from the MindCare app.',
      location: '',
      startDate: start,
      endDate: end,
      recurrence: _isRecurring ? Recurrence(frequency: Frequency.weekly) : null,
      allDay: false,
    );

    // The OS sheet lets the user confirm inside their chosen calendar app.
    final added = await Add2Calendar.addEvent2Cal(event);

    if (!mounted) return;
    if (!added) return;

    // Local confirmation so the user knows exactly where it was added.
    await NotificationService.showEventAddedNotification(
      eventTitle: 'MindCare — $selectedType',
      provider: provider,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${s.calendarAddedSnack}: $provider'),
        backgroundColor: const Color(0xFF7986CB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _HeroBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradientColors = const [Color(0xFF5BA8A0), Color(0xFF3D8B84)],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final VoidCallback? onTap;

  const _ReminderCard({required this.child, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1A2E2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconCircle({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;
  final bool isDark;
  const _InfoNote({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.green.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day picker ────────────────────────────────────────────────────────────────

class _DayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const _DayPicker({required this.selected, required this.onChanged});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1; // 1=Mon…7=Sun
        final isOn = selected.isEmpty || selected.contains(day);
        return GestureDetector(
          onTap: () {
            final next = Set<int>.from(selected);
            if (selected.isEmpty) {
              // "Every day" → deselect this one day
              next.addAll({1, 2, 3, 4, 5, 6, 7});
              next.remove(day);
            } else if (next.contains(day)) {
              next.remove(day);
              if (next.length == 7) next.clear(); // back to "every day"
            } else {
              next.add(day);
              if (next.length == 7) next.clear();
            }
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOn ? _kTeal : Colors.grey.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _days[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isOn ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Message picker ────────────────────────────────────────────────────────────

class _MessagePicker extends StatefulWidget {
  final String current;
  final bool isDark;
  final List<String> presets;
  final ValueChanged<String> onChanged;

  const _MessagePicker({
    required this.current,
    required this.isDark,
    required this.presets,
    required this.onChanged,
  });

  @override
  State<_MessagePicker> createState() => _MessagePickerState();
}

class _MessagePickerState extends State<_MessagePicker> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _commit(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) widget.onChanged(trimmed);
    });
  }

  void _selectPreset(String msg) {
    _debounce?.cancel();
    _controller.text = msg;
    _controller.selection = TextSelection.collapsed(offset: msg.length);
    widget.onChanged(msg);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom =
        !widget.presets.contains(widget.current) && widget.current.trim().isNotEmpty;
    return Column(
      children: [
        // Free-text custom message
        TextField(
          controller: _controller,
          maxLines: 3,
          minLines: 1,
          onChanged: _commit,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: widget.presets.firstOrNull ?? 'Type a reminder message…',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
            prefixIcon: const Icon(
              Icons.edit_rounded,
              size: 20,
              color: Color(0xFFFF8A65),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isCustom
                    ? const Color(0xFFFF8A65)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isCustom
                    ? const Color(0xFFFF8A65)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF8A65),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...widget.presets.map((msg) {
          final isSelected = _controller.text == msg;
          return GestureDetector(
            onTap: () => _selectPreset(msg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF8A65).withValues(alpha: 0.1)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF8A65)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: isSelected ? const Color(0xFFFF8A65) : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
