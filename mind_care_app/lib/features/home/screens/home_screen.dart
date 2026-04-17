import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/main.dart' show appUserName;

class HomeScreen extends StatefulWidget {
  final String lang;
  const HomeScreen({super.key, this.lang = 'en'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOffline = false;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  void _onUserNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
    appUserName.addListener(_onUserNameChanged);
    // Load name into global notifier if not already set
    if (appUserName.value == null) {
      PreferencesService.getUserName()
          .then((name) => appUserName.value = name);
    }
  }

  @override
  void dispose() {
    appUserName.removeListener(_onUserNameChanged);
    super.dispose();
  }

  String _greeting(bool isSinhala) {
    final hour = DateTime.now().hour;
    if (isSinhala) {
      if (hour < 12) return 'සුභ උදෑසනක්';
      if (hour < 17) return 'සුභ දහවලක්';
      return 'සුභ සන්ධ්‍යාවක්';
    } else {
      if (hour < 12) return 'Good morning';
      if (hour < 17) return 'Good afternoon';
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSinhala = widget.lang == 'si';

    // Background: teal gradient matching the design
    const bgLight = Color(0xFF7EC8C8);
    const bgDark = Color(0xFF1A3333);

    final features = isSinhala ? [
      _Feature(
        title: 'විලෝ සමග\nකතා කරන්න',
        icon: Icons.eco_outlined,
        color: isDark ? const Color(0xFF2A4040) : Colors.white.withOpacity(0.85),
        onTap: (ctx) => ctx.push('${AppRouter.willowChat}?lang=si'),
        iconColor: const Color(0xFF5BA8A0),
        layout: _CardLayout.iconLeft,
      ),
      _Feature(
        title: 'ඇමතුම් උපදේශක',
        icon: Icons.headset_mic_outlined,
        color: isDark ? const Color(0xFF1E3535) : const Color(0xFF5BA8A0),
        onTap: (ctx) => ctx.push(AppRouter.counsellorCall),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'සන්සුන් සංගීතය',
        icon: Icons.headset_outlined,
        color: isDark ? const Color(0xFF2E4A4A) : const Color(0xFF5BA8A0),
        onTap: (ctx) => ctx.push(AppRouter.calmMusic),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'මානසික පීඩනය\nදුරු කරන ක්‍රීඩා',
        icon: null,
        color: isDark ? const Color(0xFF2A3D2A) : const Color(0xFFD4EAD0),
        onTap: (ctx) => ctx.push(AppRouter.games),
        iconColor: Colors.transparent,
        layout: _CardLayout.textOnly,
      ),
      _Feature(
        title: 'මග පෙන්වන භාවනාව',
        icon: Icons.self_improvement_outlined,
        color: isDark ? const Color(0xFF2E4A4A) : const Color(0xFF5BA8A0),
        onTap: (ctx) => ctx.push(AppRouter.breathing),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'දෛනික මතක් කිරීම්',
        icon: Icons.notifications_outlined,
        color: isDark ? const Color(0xFF37474F) : Colors.white.withOpacity(0.85),
        onTap: (ctx) => ctx.push(AppRouter.dailyReminders),
        iconColor: const Color(0xFF5BA8A0),
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'ප්‍රබෝධමත්\nදිරිගැන්වීම',
        icon: null,
        color: isDark ? const Color(0xFF3D3520) : const Color(0xFFFFF8E1),
        onTap: (ctx) => ctx.push(AppRouter.motivational),
        iconColor: Colors.transparent,
        layout: _CardLayout.textOnly,
      ),
      _Feature(
        title: 'හුස්ම ගැනීමේ\nඅභ්‍යාස',
        icon: Icons.air_rounded,
        color: isDark ? const Color(0xFF1A3A3A) : const Color(0xFF4DB6AC),
        onTap: (ctx) => ctx.push(AppRouter.breathingExercises),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
    ] : [
      _Feature(
        title: 'Chat with\nWillow',
        icon: Icons.eco_outlined,
        color: isDark ? const Color(0xFF2A4040) : Colors.white.withOpacity(0.85),
        onTap: (ctx) => ctx.push('${AppRouter.willowChat}?lang=en'),
        iconColor: const Color(0xFF5BA8A0),
        layout: _CardLayout.iconLeft,
      ),
      _Feature(
        title: 'Counselor\nCall',
        icon: Icons.headset_mic_outlined,
        color: isDark ? const Color(0xFF1E3535) : const Color(0xFF5BA8A0),
        onTap: (ctx) => ctx.push(AppRouter.counsellorCall),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'Calm Music',
        icon: Icons.headset_outlined,
        color: isDark ? const Color(0xFF2E4A4A) : const Color(0xFF5BA8A0),
        onTap: (ctx) => ctx.push(AppRouter.calmMusic),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'Stress-Relief\nGames',
        icon: null,
        color: isDark ? const Color(0xFF2A3D2A) : const Color(0xFFD4EAD0),
        onTap: (ctx) => ctx.push(AppRouter.games),
        iconColor: Colors.transparent,
        layout: _CardLayout.textOnly,
      ),
      _Feature(
        title: 'Guided\nMeditation',
        icon: Icons.self_improvement_outlined,
        color: isDark ? const Color(0xFF2E4A4A) : const Color(0xFF5BA8A0),
        onTap: (ctx) => ctx.push(AppRouter.meditation),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'Daily\nReminders',
        icon: Icons.notifications_outlined,
        color: isDark ? const Color(0xFF37474F) : Colors.white.withOpacity(0.85),
        onTap: (ctx) => ctx.push(AppRouter.dailyReminders),
        iconColor: const Color(0xFF5BA8A0),
        layout: _CardLayout.iconTop,
      ),
      _Feature(
        title: 'Motivational\nBoost',
        icon: null,
        color: isDark ? const Color(0xFF3D3520) : const Color(0xFFFFF8E1),
        onTap: (ctx) => ctx.push(AppRouter.motivational),
        iconColor: Colors.transparent,
        layout: _CardLayout.textOnly,
      ),
      _Feature(
        title: 'Breathing\nExercises',
        icon: Icons.air_rounded,
        color: isDark ? const Color(0xFF1A3A3A) : const Color(0xFF4DB6AC),
        onTap: (ctx) => ctx.push(AppRouter.breathingExercises),
        iconColor: isDark ? Colors.white70 : Colors.white,
        layout: _CardLayout.iconTop,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: Stack(
        children: [
          // Decorative leaf background
          Positioned(
            top: 60,
            right: -20,
            child: Opacity(
              opacity: isDark ? 0.06 : 0.10,
              child: const Icon(Icons.eco_rounded,
                  size: 180, color: Color(0xFF004D40)),
            ),
          ),
          Positioned(
            top: 160,
            right: 40,
            child: Opacity(
              opacity: isDark ? 0.05 : 0.08,
              child: const Icon(Icons.eco_rounded,
                  size: 120, color: Color(0xFF004D40)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    color: isDark
                        ? const Color(0xFF37474F)
                        : const Color(0xFFFFECB3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF795548)),
                        const SizedBox(width: 8),
                        Text(
                          'You\'re offline — changes will sync when reconnected.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF795548),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appUserName.value != null && appUserName.value!.isNotEmpty
                            ? '${_greeting(isSinhala)},\n${appUserName.value} 👋'
                            : (isSinhala
                                ? 'ඔබ ගැන\nසැලකිලිමත් වන්න'
                                : 'Take care\nof yourself'),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF80CBC4)
                              : const Color(0xFF1A4A4A),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate aspect ratio so all 4 rows fit in available height
                        final availableHeight = constraints.maxHeight - 12; // bottom padding
                        final cardHeight = (availableHeight - (3 * 10)) / 4; // 4 rows, 3 gaps
                        final cardWidth = (constraints.maxWidth - 10) / 2; // 2 cols, 1 gap
                        final ratio = cardWidth / cardHeight;
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: ratio.clamp(0.9, 1.4),
                          ),
                          itemCount: features.length,
                          itemBuilder: (context, i) =>
                              _FeatureCard(feature: features[i], isDark: isDark),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        isDark: isDark,
        isSinhala: isSinhala,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 1) {
            context.push(AppRouter.moodHistory).then((_) {
              if (mounted) setState(() => _selectedIndex = 0);
            });
          }
          if (i == 2) {
            context.push(AppRouter.settings).then((_) {
              if (mounted) setState(() => _selectedIndex = 0);
            });
          }
        },
      ),
    );
  }
}

enum _CardLayout { iconLeft, iconTop, textOnly }

class _Feature {
  final String title;
  final IconData? icon;
  final Color color;
  final void Function(BuildContext) onTap;
  final Color iconColor;
  final _CardLayout layout;

  const _Feature({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.iconColor,
    required this.layout,
  });
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final bool isDark;

  const _FeatureCard({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? Colors.white
        : (feature.color == Colors.white.withOpacity(0.85) ||
                feature.color == const Color(0xFFFFF8E1) ||
                feature.color == const Color(0xFFD4EAD0) ||
                feature.color.alpha < 230)
            ? const Color(0xFF1A4A4A)
            : Colors.white;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => feature.onTap(context),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: feature.color,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: feature.layout == _CardLayout.iconLeft
              ? _IconLeftContent(feature: feature, textColor: textColor)
              : feature.layout == _CardLayout.iconTop
                  ? _IconTopContent(feature: feature, textColor: textColor)
                  : _TextOnlyContent(feature: feature, textColor: textColor),
        ),
      ),
    );
  }
}

class _IconLeftContent extends StatelessWidget {
  final _Feature feature;
  final Color textColor;
  const _IconLeftContent(
      {required this.feature, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFD4EAD0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: const Color(0xFF5BA8A0), size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            feature.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconTopContent extends StatelessWidget {
  final _Feature feature;
  final Color textColor;
  const _IconTopContent(
      {required this.feature, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (feature.icon != null)
          Icon(feature.icon, color: feature.iconColor, size: 32),
        if (feature.icon != null) const SizedBox(height: 10),
        Text(
          feature.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _TextOnlyContent extends StatelessWidget {
  final _Feature feature;
  final Color textColor;
  const _TextOnlyContent(
      {required this.feature, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        feature.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 1.3,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final bool isSinhala;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.isDark,
    required this.isSinhala,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? const Color(0xFF80CBC4) : const Color(0xFF1A4A4A);
    final inactiveColor = isDark ? Colors.white38 : Colors.black45;
    final activeBg =
        isDark ? const Color(0xFF2E4A4A) : const Color(0xFF1A4A4A);

    final items = isSinhala
        ? [
            (Icons.home_outlined, 'මූල් පිටුව'),
            (Icons.bar_chart_rounded, 'ප්‍රගතිය'),
            (Icons.person_outline, 'ගිණුම'),
          ]
        : [
            (Icons.home_outlined, 'Home'),
            (Icons.bar_chart_rounded, 'Progress'),
            (Icons.person_outline, 'Profile'),
          ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A2A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = selectedIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selected ? activeBg : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        items[i].$1,
                        color: selected ? Colors.white : inactiveColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? activeColor : inactiveColor,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
