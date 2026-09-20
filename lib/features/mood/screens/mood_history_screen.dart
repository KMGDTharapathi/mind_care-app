import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';
import 'package:mind_care_app/data/repositories/mood_repository.dart';

/// Maps MoodType to a numeric value for the chart Y-axis.
double _moodValue(MoodType mood) {
  switch (mood) {
    case MoodType.sad:
      return 1;
    case MoodType.anxious:
      return 2;
    case MoodType.tired:
      return 2;
    case MoodType.frustrated:
      return 3;
    case MoodType.calm:
      return 4;
    case MoodType.happy:
      return 5;
    case MoodType.excited:
      return 6;
  }
}

String _moodEmoji(MoodType mood) {
  switch (mood) {
    case MoodType.happy:
      return '😊';
    case MoodType.sad:
      return '😔';
    case MoodType.anxious:
      return '😰';
    case MoodType.frustrated:
      return '😤';
    case MoodType.calm:
      return '😌';
    case MoodType.excited:
      return '🤩';
    case MoodType.tired:
      return '😴';
  }
}

String _moodLabel(MoodType mood, {bool isSinhala = false}) {
  if (isSinhala) {
    switch (mood) {
      case MoodType.happy:
        return 'සතුටු';
      case MoodType.sad:
        return 'දුකින්';
      case MoodType.anxious:
        return 'කනස්සල්ලෙන්';
      case MoodType.frustrated:
        return 'කලකිරීමෙන්';
      case MoodType.calm:
        return 'සන්සුන්';
      case MoodType.excited:
        return 'උද්යෝගිමත්';
      case MoodType.tired:
        return 'වෙහෙසට';
    }
  }
  switch (mood) {
    case MoodType.happy:
      return 'Happy';
    case MoodType.sad:
      return 'Sad';
    case MoodType.anxious:
      return 'Anxious';
    case MoodType.frustrated:
      return 'Frustrated';
    case MoodType.calm:
      return 'Calm';
    case MoodType.excited:
      return 'Excited';
    case MoodType.tired:
      return 'Tired';
  }
}

class MoodHistoryScreen extends StatefulWidget {
  final MoodRepository repository;

  const MoodHistoryScreen({super.key, required this.repository});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  late Future<List<MoodEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = widget.repository.getLast7Days();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(),
              Expanded(
                child: FutureBuilder<List<MoodEntry>>(
                  future: _entriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final entries = snapshot.data ?? [];
                    return _HistoryContent(entries: entries);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          Text(
            s.moodHistory,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  final List<MoodEntry> entries;

  const _HistoryContent({required this.entries});

  /// Build a map of day-offset (0=6 days ago, 6=today) → MoodEntry (last entry per day)
  Map<int, MoodEntry> _buildDayMap() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final map = <int, MoodEntry>{};

    for (final entry in entries) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final diff = todayDate.difference(entryDate).inDays;
      if (diff >= 0 && diff <= 6) {
        final index = 6 - diff; // 0 = 6 days ago, 6 = today
        map[index] = entry;
      }
    }
    return map;
  }

  List<String> _buildDayLabels() {
    final today = DateTime.now();
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return dayNames[date.weekday - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final dayMap = _buildDayMap();
    final dayLabels = _buildDayLabels();

    // Determine mood trend for encouragement/appreciation banner
    String? bannerTitle;
    String? bannerBody;
    Gradient? bannerGradient;
    IconData? bannerIcon;

    if (entries.isNotEmpty) {
      int positive = 0;
      int negative = 0;
      for (final entry in entries) {
        switch (entry.mood) {
          case MoodType.happy:
          case MoodType.calm:
          case MoodType.excited:
            positive++;
            break;
          case MoodType.sad:
          case MoodType.anxious:
          case MoodType.frustrated:
          case MoodType.tired:
            negative++;
            break;
        }
      }
      if (negative > positive) {
        bannerTitle = s.moodEncouragementTitle;
        bannerBody = s.moodEncouragementBody;
        bannerGradient = const LinearGradient(
          colors: [Color(0xFFE57373), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        bannerIcon = Icons.favorite_rounded;
      } else if (positive > negative) {
        bannerTitle = s.moodAppreciationTitle;
        bannerBody = s.moodAppreciationBody;
        bannerGradient = const LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        bannerIcon = Icons.star_rounded;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encouragement / Appreciation banner
          if (bannerTitle != null && bannerBody != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: bannerGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (bannerGradient!.colors.first).withValues(
                      alpha: 0.4,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(bannerIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bannerTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bannerBody,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            s.last7Days,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            s.moodOverPastWeek,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _MoodChart(dayMap: dayMap, dayLabels: dayLabels),
          const SizedBox(height: 28),
          _MoodLegend(),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            Center(
              child: Column(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    s.noMoodEntries,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.startLoggingMood,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            _RecentEntries(entries: entries),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _MoodChart extends StatelessWidget {
  final Map<int, MoodEntry> dayMap;
  final List<String> dayLabels;

  const _MoodChart({required this.dayMap, required this.dayLabels});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final barGroups = List.generate(7, (i) {
      final entry = dayMap[i];
      final value = entry != null ? _moodValue(entry.mood) : 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: entry != null
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.15),
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          maxY: 7,
          minY: 0,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  final labels = {
                    1.0: '😔',
                    2.0: '😰',
                    3.0: '😤',
                    4.0: '😌',
                    5.0: '😊',
                    6.0: '🤩',
                  };
                  final emoji = labels[value];
                  if (emoji == null) return const SizedBox.shrink();
                  return Text(emoji, style: const TextStyle(fontSize: 14));
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= dayLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dayLabels[idx],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = dayMap[group.x];
                if (entry == null) return null;
                return BarTooltipItem(
                  '${_moodEmoji(entry.mood)} ${_moodLabel(entry.mood)}',
                  TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _MoodLegend extends StatelessWidget {
  final _items = const [
    ('😔', 'Sad', 1),
    ('😰', 'Anxious', 2),
    ('😤', 'Frustrated', 3),
    ('😌', 'Calm', 4),
    ('😊', 'Happy', 5),
    ('🤩', 'Excited', 6),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${item.$2} (${item.$3})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

// ── Recent entries list ───────────────────────────────────────────────────────

class _RecentEntries extends StatelessWidget {
  final List<MoodEntry> entries;
  const _RecentEntries({required this.entries});

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final reversed = entries.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.recentEntries,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...reversed.map((entry) => _EntryTile(entry: entry)),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final MoodEntry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(_moodEmoji(entry.mood), style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _moodLabel(entry.mood, isSinhala: s.isSinhala),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  Text(
                    entry.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(entry.timestamp, s),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt, s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(entryDate).inDays;

    if (diff == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff == 1) {
      return s.yesterdayLabel;
    } else {
      return '${dt.month}/${dt.day}';
    }
  }
}
