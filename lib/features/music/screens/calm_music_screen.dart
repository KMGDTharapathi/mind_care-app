import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String emoji;
  final Color color;
  final String url;
  final bool isDefault;
  final bool isLocal; // true = local file path, false = network URL

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.emoji,
    required this.color,
    required this.url,
    this.isDefault = true,
    this.isLocal = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  DEFAULT TRACKS
// ─────────────────────────────────────────────────────────────────────────────
final List<MusicTrack> kDefaultTracks = [
  const MusicTrack(
    id: 'rain',
    title: 'Gentle Rain',
    artist: 'Nature Sounds',
    emoji: '🌧️',
    color: Color(0xFF4A90D9),
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  ),
  const MusicTrack(
    id: 'forest',
    title: 'Forest Morning',
    artist: 'Nature Sounds',
    emoji: '🌲',
    color: Color(0xFF43A047),
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  ),
  const MusicTrack(
    id: 'ocean',
    title: 'Ocean Waves',
    artist: 'Nature Sounds',
    emoji: '🌊',
    color: Color(0xFF0288D1),
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ),
  const MusicTrack(
    id: 'piano',
    title: 'Soft Piano',
    artist: 'Calm Melodies',
    emoji: '🎹',
    color: Color(0xFF7B1FA2),
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
  ),
  const MusicTrack(
    id: 'lofi',
    title: 'Lo-Fi Chill',
    artist: 'Calm Melodies',
    emoji: '🎧',
    color: Color(0xFFE65100),
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
  ),
  const MusicTrack(
    id: 'birds',
    title: 'Morning Birds',
    artist: 'Nature Sounds',
    emoji: '🐦',
    color: Color(0xFFF9A825),
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
  ),
];

// Emoji options for user tracks — first 16 shown by default, rest on expand
const List<String> kEmojiOptions = [
  '🎵', '🎶', '🎸', '🎹', '🎺', '🎻', '🥁', '🎷',
  '🌙', '⭐', '🌊', '🌿', '🔥', '💫', '🌸', '🎧',
];

const List<String> kEmojiOptionsExtra = [
  '🎼', '🎤', '🎙️', '📻', '🎚️', '🎛️', '🔔', '🔕',
  '🎃', '🎄', '🎆', '🎇', '✨', '🌟', '💥', '🌈',
  '🌺', '🌻', '🌹', '🍀', '🦋', '🐬', '🦜', '🐧',
  '🌍', '🌙', '☀️', '⛅', '🌊', '🏔️', '🌴', '🌵',
  '❤️', '💙', '💚', '💛', '💜', '🖤', '🤍', '🧡',
  '🎯', '🏆', '🎪', '🎭', '🎨', '🖼️', '🎬', '📽️',
  '🚀', '🛸', '🌌', '🔭', '⚡', '🌀', '💎', '🔮',
];

// Color options — first 10 shown by default
const List<Color> kColorOptions = [
  Color(0xFF5BA8A0), Color(0xFF4A90D9), Color(0xFF43A047),
  Color(0xFF7B1FA2), Color(0xFFE65100), Color(0xFFF9A825),
  Color(0xFFE91E63), Color(0xFF00BCD4), Color(0xFF795548),
  Color(0xFF607D8B),
];

// Extended color palette shown when user taps +
const List<Color> kColorOptionsExtra = [
  // Reds
  Color(0xFFB71C1C), Color(0xFFE53935), Color(0xFFEF9A9A),
  // Pinks
  Color(0xFF880E4F), Color(0xFFE91E63), Color(0xFFF48FB1),
  // Purples
  Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFCE93D8),
  // Blues
  Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF90CAF9),
  // Teals
  Color(0xFF004D40), Color(0xFF00796B), Color(0xFF80CBC4),
  // Greens
  Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFFA5D6A7),
  // Yellows
  Color(0xFFF57F17), Color(0xFFFBC02D), Color(0xFFFFF176),
  // Oranges
  Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFFCC80),
  // Browns
  Color(0xFF3E2723), Color(0xFF6D4C41), Color(0xFFBCAAA4),
  // Greys
  Color(0xFF212121), Color(0xFF616161), Color(0xFFBDBDBD),
];

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CalmMusicScreen extends StatefulWidget {
  const CalmMusicScreen({super.key});
  @override
  State<CalmMusicScreen> createState() => _CalmMusicScreenState();
}

class _CalmMusicScreenState extends State<CalmMusicScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();

  List<MusicTrack> _userTracks = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  // ValueNotifiers — only the widgets that subscribe to these will rebuild
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  // 0 = library, 1 = now playing, 2 = my playlist
  int _tab = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  List<MusicTrack> get _allTracks => [...kDefaultTracks, ..._userTracks];
  MusicTrack get _current => _allTracks[_currentIndex.clamp(0, _allTracks.length - 1)];

  static const _prefKey = 'calm_music_user_tracks_v2';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Throttle position updates to once per second — progress bar shows seconds only
    Duration _lastPos = Duration.zero;
    _player.onPositionChanged.listen((d) {
      if ((d.inSeconds - _lastPos.inSeconds).abs() >= 1) {
        _lastPos = d;
        _position.value = d;
      }
    });
    _player.onDurationChanged.listen((d) { _duration.value = d; });
    _player.onPlayerStateChanged.listen((s) {
      _isPlaying.value = s == PlayerState.playing;
      // Pause pulse animation when not playing to save CPU
      if (s == PlayerState.playing) {
        if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
      }
    });
    _player.onPlayerComplete.listen((_) => _playNext());
    _loadUserTracks();
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseCtrl.dispose();
    _position.dispose();
    _duration.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _loadUserTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefKey) ?? [];
      final loaded = raw.map((s) {
        final p = s.split('|||');
        if (p.length < 6) return null;
        return MusicTrack(
          id: p[0], title: p[1], artist: p[2], emoji: p[3],
          color: Color(int.tryParse(p[4]) ?? 0xFF5BA8A0),
          url: p[5], isDefault: false,
          isLocal: p.length > 6 && p[6] == '1',
        );
      }).whereType<MusicTrack>().toList();
      if (mounted) setState(() => _userTracks = loaded);
    } catch (_) {}
  }

  Future<void> _saveUserTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _userTracks.map((t) =>
          '${t.id}|||${t.title}|||${t.artist}|||${t.emoji}|||${t.color.value}|||${t.url}|||${t.isLocal ? '1' : '0'}'
      ).toList());
    } catch (_) {}
  }

  // ── Playback ───────────────────────────────────────────────────────────────
  Future<void> _play(int index) async {
    final all = _allTracks;
    if (index < 0 || index >= all.length) return;
    setState(() { _currentIndex = index; _isLoading = true; _tab = 1; });
    try {
      await _player.stop();
      final source = all[index].isLocal
          ? DeviceFileSource(all[index].url)
          : UrlSource(all[index].url) as Source;
      await _player.play(source);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying.value) {
      await _player.pause();
    } else {
      if (_position.value == Duration.zero) {
        await _play(_currentIndex);
      } else {
        await _player.resume();
      }
    }
  }

  void _playNext() {
    _play((_currentIndex + 1) % _allTracks.length);
  }

  void _playPrev() {
    if (_position.value.inSeconds > 3) { _player.seek(Duration.zero); return; }
    _play((_currentIndex - 1 + _allTracks.length) % _allTracks.length);
  }

  // ── User track management ──────────────────────────────────────────────────
  void _addTrack(MusicTrack track) {
    setState(() => _userTracks.add(track));
    _saveUserTracks();
  }

  void _deleteUserTrack(int userIndex) {
    final globalIndex = kDefaultTracks.length + userIndex;
    if (_currentIndex == globalIndex && _isPlaying.value) _player.stop();
    setState(() {
      if (_currentIndex >= globalIndex && _currentIndex > 0) _currentIndex--;
      _userTracks.removeAt(userIndex);
    });
    _saveUserTracks();
  }

  void _reorderUserTracks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _userTracks.removeAt(oldIndex);
      _userTracks.insert(newIndex, item);
    });
    _saveUserTracks();
  }

  void _editUserTrack(int userIndex, MusicTrack updated) {
    setState(() => _userTracks[userIndex] = updated);
    _saveUserTracks();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Back navigation ────────────────────────────────────────────────────────
  void _handleBack() {
    if (_tab != 0) {
      setState(() => _tab = 0); // go to Library, keep music playing
    } else {
      Navigator.of(context).pop(); // actually leave the screen
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1F1F) : const Color(0xFFF0F9F9);

    return PopScope(
      canPop: false, // we handle it ourselves
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildTabBar(isDark),
              Expanded(child: _buildBody(isDark)),
            ],
          ),
        ),
        floatingActionButton: _tab == 2
            ? FloatingActionButton.extended(
                onPressed: () => _showAddSheet(context, isDark),
                backgroundColor: const Color(0xFF5BA8A0),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(LanguageProvider.of(context).addMusic, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final s = LanguageProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF1A4A4A)),
            onPressed: _handleBack,
          ),
          const Spacer(),
          Text(
            _tab == 1 ? s.nowPlayingTab : _tab == 2 ? s.myPlaylistTab : s.calmMusicTitle,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A4A4A)),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final s = LanguageProvider.of(context);
    final tabs = [
      (Icons.library_music_rounded, s.libraryTab),
      (Icons.play_circle_rounded, s.nowPlayingTab),
      (Icons.queue_music_rounded, s.myPlaylistTab),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final selected = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF5BA8A0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.value.$1,
                        size: 18,
                        color: selected ? Colors.white : (isDark ? Colors.white38 : Colors.black38)),
                    const SizedBox(height: 3),
                    Text(e.value.$2,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? Colors.white : (isDark ? Colors.white38 : Colors.black38))),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_tab) {
      case 0: return _buildLibrary(isDark);
      case 1: return _buildNowPlaying(isDark);
      case 2: return _buildMyPlaylist(isDark);
      default: return _buildLibrary(isDark);
    }
  }

  // ── Library tab ────────────────────────────────────────────────────────────
  Widget _buildLibrary(bool isDark) {
    final all = _allTracks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini player only rebuilds when isPlaying/position changes
        ValueListenableBuilder2<bool, Duration>(
          first: _isPlaying,
          second: _position,
          builder: (_, playing, pos, __) =>
              (playing || pos > Duration.zero) ? _buildMiniPlayer(isDark) : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Text('All Tracks',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF2A5A5A))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5BA8A0).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${all.length}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5BA8A0), fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final track = all[i];
              return ValueListenableBuilder2<bool, int>(
                first: _isPlaying,
                second: ValueNotifier(_currentIndex), // static snapshot is fine here
                builder: (_, playing, __, ___) => _TrackTile(
                  track: track,
                  isPlaying: playing && _currentIndex == i,
                  isCurrent: _currentIndex == i,
                  isDark: isDark,
                  onTap: () => _play(i),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── My Playlist tab ────────────────────────────────────────────────────────
  Widget _buildMyPlaylist(bool isDark) {
    if (_userTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF5BA8A0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note_rounded, size: 44, color: Color(0xFF5BA8A0)),
            ),
            const SizedBox(height: 20),
            Text('Your playlist is empty',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF2A5A5A))),
            const SizedBox(height: 8),
            Text('Tap + Add Music to get started',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder2<bool, Duration>(
          first: _isPlaying,
          second: _position,
          builder: (_, playing, pos, __) =>
              (playing || pos > Duration.zero) ? _buildMiniPlayer(isDark) : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            Text('My Music',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF2A5A5A))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5BA8A0).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${_userTracks.length}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5BA8A0), fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            Text('Hold & drag to reorder',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black26)),
          ]),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: _userTracks.length,
            onReorder: _reorderUserTracks,
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent, elevation: 8,
              borderRadius: BorderRadius.circular(16), child: child,
            ),
            itemBuilder: (_, i) {
              final globalIndex = kDefaultTracks.length + i;
              return Padding(
                key: ValueKey(_userTracks[i].id),
                padding: const EdgeInsets.only(bottom: 8),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isPlaying,
                  builder: (_, playing, __) => _UserTrackTile(
                    track: _userTracks[i],
                    isPlaying: playing && _currentIndex == globalIndex,
                    isCurrent: _currentIndex == globalIndex,
                    isDark: isDark,
                    onTap: () => _play(globalIndex),
                    onEdit: () => _showEditSheet(context, isDark, i),
                    onDelete: () => _confirmDelete(context, isDark, i),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Now Playing tab ────────────────────────────────────────────────────────
  Widget _buildNowPlaying(bool isDark) {
    final track = _current;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Album art — pulses only when playing
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) => ScaleTransition(
              scale: playing ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    track.color.withOpacity(0.9),
                    track.color.withOpacity(0.4),
                    track.color.withOpacity(0.08),
                  ]),
                  boxShadow: [BoxShadow(color: track.color.withOpacity(0.45), blurRadius: 40, spreadRadius: 6)],
                ),
                child: Center(child: Text(track.emoji, style: const TextStyle(fontSize: 88))),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(track.title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A3333)),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(track.artist,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : const Color(0xFF5BA8A0))),
          const SizedBox(height: 28),
          // Progress bar — only this widget rebuilds on position tick
          _ProgressBar(
            position: _position,
            duration: _duration,
            color: track.color,
            isDark: isDark,
            onSeek: (v) => _player.seek(Duration(seconds: v.toInt())),
          ),
          const SizedBox(height: 20),
          // Play/pause button — only rebuilds on play state change
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ctrlBtn(Icons.skip_previous_rounded, 34, _playPrev, isDark),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _isLoading ? null : _togglePlay,
                  child: Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: track.color,
                      boxShadow: [BoxShadow(color: track.color.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
                    ),
                    child: _isLoading
                        ? const Padding(padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white, size: 38),
                  ),
                ),
                const SizedBox(width: 16),
                _ctrlBtn(Icons.skip_next_rounded, 34, _playNext, isDark),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Queue',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : const Color(0xFF5BA8A0))),
          ),
          const SizedBox(height: 8),
          // Queue rows — only isPlaying indicator rebuilds
          ..._allTracks.asMap().entries.map((e) => ValueListenableBuilder<bool>(
                valueListenable: _isPlaying,
                builder: (_, playing, __) => _QueueRow(
                  track: e.value,
                  isCurrent: e.key == _currentIndex,
                  isPlaying: playing && e.key == _currentIndex,
                  isDark: isDark,
                  onTap: () => _play(e.key),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, double size, VoidCallback onTap, bool isDark) =>
      IconButton(
        icon: Icon(icon, size: size, color: isDark ? Colors.white70 : const Color(0xFF2A5A5A)),
        onPressed: onTap,
      );

  // ── Mini player bar ────────────────────────────────────────────────────────
  Widget _buildMiniPlayer(bool isDark) {
    final track = _current;
    return GestureDetector(
      onTap: () => setState(() => _tab = 1),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: track.color.withOpacity(isDark ? 0.28 : 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: track.color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(children: [
          Text(track.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1A3333))),
              Text(track.artist,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF5BA8A0))),
            ]),
          ),
          // Only the icon rebuilds on play state change
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) => IconButton(
              icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: track.color, size: 34),
              onPressed: _togglePlay,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Add / Edit sheets ──────────────────────────────────────────────────────
  void _showAddSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackFormSheet(
        isDark: isDark,
        onSave: (track) { _addTrack(track); Navigator.pop(context); },
      ),
    );
  }

  void _showEditSheet(BuildContext context, bool isDark, int userIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackFormSheet(
        isDark: isDark,
        existing: _userTracks[userIndex],
        onSave: (track) { _editUserTrack(userIndex, track); Navigator.pop(context); },
      ),
    );
  }

  void _confirmDelete(BuildContext context, bool isDark, int userIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Track',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A3333))),
        content: Text('Remove "${_userTracks[userIndex].title}" from your playlist?',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF5BA8A0))),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteUserTrack(userIndex); },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRACK TILE (library)
// ─────────────────────────────────────────────────────────────────────────────
class _TrackTile extends StatelessWidget {
  final MusicTrack track;
  final bool isPlaying, isCurrent, isDark;
  final VoidCallback onTap;

  const _TrackTile({
    required this.track, required this.isPlaying, required this.isCurrent,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isCurrent
                ? track.color.withOpacity(isDark ? 0.22 : 0.1)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? track.color.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isCurrent ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: track.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(track.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(track.title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1A3333))),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(track.artist,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF5BA8A0))),
                    if (!track.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5BA8A0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('My Music', style: TextStyle(fontSize: 9, color: Color(0xFF5BA8A0))),
                      ),
                    ],
                  ]),
                ]),
              ),
              if (isPlaying) _WaveIcon(color: track.color)
              else Icon(Icons.play_circle_outline_rounded, color: track.color, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  USER TRACK TILE (my playlist — with edit/delete)
// ─────────────────────────────────────────────────────────────────────────────
class _UserTrackTile extends StatelessWidget {
  final MusicTrack track;
  final bool isPlaying, isCurrent, isDark;
  final VoidCallback onTap, onEdit, onDelete;

  const _UserTrackTile({
    required this.track, required this.isPlaying, required this.isCurrent,
    required this.isDark, required this.onTap, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isCurrent
                ? track.color.withOpacity(isDark ? 0.22 : 0.1)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? track.color.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isCurrent ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              // Drag handle
              Icon(Icons.drag_handle_rounded, color: isDark ? Colors.white24 : Colors.black12, size: 20),
              const SizedBox(width: 8),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: track.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(track.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(track.title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1A3333))),
                  const SizedBox(height: 2),
                  Text(track.artist,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF5BA8A0))),
                ]),
              ),
              if (isPlaying) ...[
                _WaveIcon(color: track.color),
                const SizedBox(width: 4),
              ],
              // Edit
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18,
                    color: isDark ? Colors.white38 : Colors.black26),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Delete
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18,
                    color: Colors.red.withOpacity(0.6)),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QUEUE ROW (now playing tab)
// ─────────────────────────────────────────────────────────────────────────────
class _QueueRow extends StatelessWidget {
  final MusicTrack track;
  final bool isCurrent, isPlaying, isDark;
  final VoidCallback onTap;

  const _QueueRow({
    required this.track, required this.isCurrent, required this.isPlaying,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Text(track.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(track.title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? track.color : (isDark ? Colors.white70 : const Color(0xFF1A3333)))),
      subtitle: Text(track.artist,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
      trailing: isPlaying
          ? _WaveIcon(color: track.color)
          : Icon(Icons.play_arrow_rounded,
              color: isDark ? Colors.white24 : Colors.black12, size: 18),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ANIMATED WAVE ICON
// ─────────────────────────────────────────────────────────────────────────────
class _WaveIcon extends StatefulWidget {
  final Color color;
  const _WaveIcon({required this.color});
  @override
  State<_WaveIcon> createState() => _WaveIconState();
}

class _WaveIconState extends State<_WaveIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final h = 6.0 + 10.0 * (((_ctrl.value + i * 0.33) % 1.0));
          return Container(
            width: 3, height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
          );
        }),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
//  PROGRESS BAR — isolated widget so only it rebuilds on position tick
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final Color color;
  final bool isDark;
  final ValueChanged<double> onSeek;

  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.color,
    required this.isDark,
    required this.onSeek,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder2<Duration, Duration>(
      first: position,
      second: duration,
      builder: (_, pos, dur, __) {
        final maxSec = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
        final curSec = pos.inSeconds.toDouble().clamp(0.0, maxSec);
        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: color,
                inactiveTrackColor: color.withOpacity(0.2),
                thumbColor: color,
                overlayColor: color.withOpacity(0.2),
              ),
              child: Slider(value: curSec, max: maxSec, onChanged: onSeek),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(pos),
                      style: TextStyle(fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38)),
                  Text(_fmt(dur),
                      style: TextStyle(fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ValueListenableBuilder2 — listens to two notifiers, rebuilds only when
//  either changes (avoids nesting two builders)
// ─────────────────────────────────────────────────────────────────────────────
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (ctx, a, _) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (ctx2, b, __) => builder(ctx2, a, b, child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD / EDIT TRACK FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _TrackFormSheet extends StatefulWidget {
  final bool isDark;
  final MusicTrack? existing;
  final void Function(MusicTrack) onSave;

  const _TrackFormSheet({required this.isDark, this.existing, required this.onSave});

  @override
  State<_TrackFormSheet> createState() => _TrackFormSheetState();
}

class _TrackFormSheetState extends State<_TrackFormSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _artistCtrl;
  late TextEditingController _urlCtrl;
  late String _selectedEmoji;
  late Color _selectedColor;
  bool _urlError = false;
  bool _titleError = false;
  bool _showMoreEmojis = false;
  bool _showMoreColors = false;

  // 0 = browse phone, 1 = paste URL
  int _sourceMode = 0;
  String? _localFilePath;
  String? _localFileName;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _artistCtrl = TextEditingController(text: e?.artist ?? '');
    _urlCtrl = TextEditingController(text: (e != null && !e.isLocal) ? e.url : '');
    _selectedEmoji = e?.emoji ?? '🎵';
    _selectedColor = e?.color ?? const Color(0xFF5BA8A0);
    if (e != null && e.isLocal) {
      _sourceMode = 0;
      _localFilePath = e.url;
      _localFileName = e.url.split('/').last;
    } else if (e != null && !e.isLocal && e.url.isNotEmpty) {
      _sourceMode = 1;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final nameWithoutExt = file.name.contains('.')
            ? file.name.substring(0, file.name.lastIndexOf('.'))
            : file.name;
        setState(() {
          _localFilePath = file.path!;
          _localFileName = file.name;
          if (_titleCtrl.text.trim().isEmpty) _titleCtrl.text = nameWithoutExt;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final hasSource = _sourceMode == 0
        ? _localFilePath != null
        : _urlCtrl.text.trim().isNotEmpty;
    setState(() {
      _titleError = title.isEmpty;
      _urlError = !hasSource;
    });
    if (title.isEmpty || !hasSource) return;

    widget.onSave(MusicTrack(
      id: widget.existing?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: _artistCtrl.text.trim().isEmpty ? 'My Music' : _artistCtrl.text.trim(),
      emoji: _selectedEmoji,
      color: _selectedColor,
      url: _sourceMode == 0 ? _localFilePath! : _urlCtrl.text.trim(),
      isDefault: false,
      isLocal: _sourceMode == 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF152525) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(children: [
                // Back arrow to close the sheet
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF0F9F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : const Color(0xFF1A4A4A)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA8A0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: Color(0xFF5BA8A0), size: 22),
                ),
                const SizedBox(width: 10),
                Text(isEdit ? 'Edit Track' : 'Add to My Playlist',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A3333))),
              ]),
              const SizedBox(height: 24),

              // ── Source toggle (only on add) ────────────────────────────────
              if (!isEdit) ...[
                Text('Music source',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF0F9F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    _sourceTab(0, Icons.phone_android_rounded, 'From Phone', isDark),
                    _sourceTab(1, Icons.link_rounded, 'Paste URL', isDark),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // ── Browse phone ───────────────────────────────────────────────
              if (_sourceMode == 0) ...[
                GestureDetector(
                  onTap: _isPicking ? null : _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _localFilePath != null
                          ? const Color(0xFF5BA8A0).withOpacity(isDark ? 0.18 : 0.07)
                          : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5FAFA)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _urlError && _localFilePath == null
                            ? Colors.red
                            : _localFilePath != null
                                ? const Color(0xFF5BA8A0).withOpacity(0.5)
                                : (isDark ? Colors.white12 : Colors.black12),
                        width: 1.5,
                      ),
                    ),
                    child: _isPicking
                        ? const Center(
                            child: SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF5BA8A0))))
                        : Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5BA8A0).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _localFilePath != null
                                    ? Icons.audio_file_rounded
                                    : Icons.folder_open_rounded,
                                color: const Color(0xFF5BA8A0), size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  _localFilePath != null ? _localFileName! : 'Browse your phone',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF1A3333)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _localFilePath != null
                                      ? 'Tap to change file'
                                      : 'MP3 · AAC · OGG · FLAC · WAV',
                                  style: TextStyle(fontSize: 11,
                                      color: isDark ? Colors.white38 : Colors.black38),
                                ),
                              ]),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: isDark ? Colors.white30 : Colors.black26),
                          ]),
                  ),
                ),
                if (_urlError && _localFilePath == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 4),
                    child: const Text('Please select an audio file',
                        style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                const SizedBox(height: 16),
              ],

              // ── Paste URL ──────────────────────────────────────────────────
              if (_sourceMode == 1) ...[
                _field(_urlCtrl, 'Audio URL (mp3 / ogg / m4a)', Icons.link_rounded, isDark,
                    keyboardType: TextInputType.url,
                    error: _urlError ? 'URL is required' : null),
                const SizedBox(height: 6),
                Text('Paste a direct link to an audio file',
                    style: TextStyle(fontSize: 11,
                        color: isDark ? Colors.white30 : Colors.black26)),
                const SizedBox(height: 16),
              ],

              // ── Emoji picker ───────────────────────────────────────────────
              Row(
                children: [
                  Text('Pick an icon',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showMoreEmojis = !_showMoreEmojis),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showMoreEmojis
                            ? const Color(0xFF5BA8A0)
                            : const Color(0xFF5BA8A0).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          _showMoreEmojis ? Icons.keyboard_hide_rounded : Icons.add_rounded,
                          size: 14,
                          color: _showMoreEmojis ? Colors.white : const Color(0xFF5BA8A0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showMoreEmojis ? 'Less' : 'More',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: _showMoreEmojis ? Colors.white : const Color(0xFF5BA8A0),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _showMoreEmojis
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: kEmojiOptions.map((e) => _emojiChip(e, isDark)).toList(),
                ),
                secondChild: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5FAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF5BA8A0).withOpacity(0.2), width: 1),
                  ),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      ...kEmojiOptions.map((e) => _emojiChip(e, isDark)),
                      ...kEmojiOptionsExtra.map((e) => _emojiChip(e, isDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Color picker ───────────────────────────────────────────────
              Row(
                children: [
                  Text('Pick a color',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showMoreColors = !_showMoreColors),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showMoreColors
                            ? const Color(0xFF5BA8A0)
                            : const Color(0xFF5BA8A0).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          _showMoreColors ? Icons.palette : Icons.add_rounded,
                          size: 14,
                          color: _showMoreColors ? Colors.white : const Color(0xFF5BA8A0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showMoreColors ? 'Less' : 'More',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: _showMoreColors ? Colors.white : const Color(0xFF5BA8A0),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _showMoreColors
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Wrap(
                  spacing: 10, runSpacing: 8,
                  children: kColorOptions.map((c) => _colorDot(c)).toList(),
                ),
                secondChild: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5FAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF5BA8A0).withOpacity(0.2), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Default row
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: kColorOptions.map((c) => _colorDot(c)).toList(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: isDark ? Colors.white12 : Colors.black12,
                          height: 1,
                        ),
                      ),
                      // Extended palette — grouped in rows of 3 (like MS Word)
                      ...List.generate((kColorOptionsExtra.length / 3).ceil(), (row) {
                        final start = row * 3;
                        final end = (start + 3).clamp(0, kColorOptionsExtra.length);
                        final rowColors = kColorOptionsExtra.sublist(start, end);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: rowColors.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _colorDot(c, size: 28),
                            )).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Song title ─────────────────────────────────────────────────
              _field(_titleCtrl, 'Song Title *', Icons.title_rounded, isDark,
                  error: _titleError ? 'Title is required' : null),
              const SizedBox(height: 12),

              // ── Artist ─────────────────────────────────────────────────────
              _field(_artistCtrl, 'Artist name (optional)', Icons.person_outline_rounded, isDark),
              const SizedBox(height: 20),

              // ── Live preview card ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _selectedColor.withOpacity(0.3), width: 1.5),
                ),
                child: Row(children: [
                  Text(_selectedEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _titleCtrl.text.trim().isEmpty ? 'Song Title' : _titleCtrl.text.trim(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF1A3333)),
                      ),
                      Text(
                        _artistCtrl.text.trim().isEmpty ? 'My Music' : _artistCtrl.text.trim(),
                        style: TextStyle(fontSize: 12, color: _selectedColor),
                      ),
                    ]),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _sourceMode == 0 ? Icons.phone_android_rounded : Icons.cloud_rounded,
                      size: 13, color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.play_circle_rounded, color: _selectedColor, size: 28),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Save button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BA8A0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Add to Playlist',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiChip(String e, bool isDark) {
    final sel = e == _selectedEmoji;
    return GestureDetector(
      onTap: () => setState(() => _selectedEmoji = e),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: sel
              ? _selectedColor.withOpacity(0.2)
              : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? _selectedColor : Colors.transparent, width: 2),
        ),
        child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
      ),
    );
  }

  Widget _colorDot(Color c, {double size = 32}) {
    final sel = c.value == _selectedColor.value;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size, height: size,
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2.5),
          boxShadow: sel
              ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
      ),
    );
  }

  Widget _sourceTab(int index, IconData icon, String label, bool isDark) {
    final sel = _sourceMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sourceMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF5BA8A0) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: sel ? Colors.white : (isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      color: sel ? Colors.white : (isDark ? Colors.white38 : Colors.black38))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool isDark, {
    TextInputType? keyboardType,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A3333)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF5BA8A0), size: 20),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF5FAFA),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: error != null
                  ? const BorderSide(color: Colors.red, width: 1.5)
                  : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4),
            child: Text(error, style: const TextStyle(fontSize: 11, color: Colors.red)),
          ),
      ],
    );
  }
}
