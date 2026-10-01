import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:mind_care_app/features/music/models/music_track.dart';

/// Audio handler backing the platform media session (notification + lock
/// screen -> play / pause / next / previous / seek).
///
/// One instance is registered with [AudioService.init] so the OS keeps a
/// foreground service alive while the queue is playing — this lets the music
/// continue when the app moves to the background instead of being killed.
class CalmAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  List<MusicTrack> _queue = [];
  int _index = 0;

  // UI-facing notifiers (same shape as CalmMusicScreen used to own).
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> isPlayingValue = ValueNotifier(false);
  final ValueNotifier<int> indexNotifier = ValueNotifier(-1);

  /// Bridge used by [AudioService] to reach the registered handler even from
  /// outside the widget tree (set right after init succeeds).
  static CalmAudioHandler? instance;

  CalmAudioHandler() {
    _player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
      ),
    );

    // Throttle position to 1/sec so the progress slider isn't flooded.
    Duration lastPos = Duration.zero;
    _player.onPositionChanged.listen((d) {
      if ((d - lastPos).inSeconds.abs() >= 1) {
        lastPos = d;
        position.value = d;
      }
    });
    _player.onDurationChanged.listen((d) {
      duration.value = d;
      final item = mediaItem.value;
      if (item != null) {
        mediaItem.add(item.copyWith(duration: d));
      }
    });
    _player.onPlayerStateChanged.listen((s) {
      isPlayingValue.value = s == PlayerState.playing;
      _broadcastPlaybackState(s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) async {
      if (_queue.isEmpty) return;
      _pushIndex((_index + 1) % _queue.length);
    });
  }

  /// Replaces the playlist shown to the OS media session.
  void setQueue(List<MusicTrack> tracks) {
    _queue = List.of(tracks);
    if (_queue.isNotEmpty) {
      super.queue.add(_queue.map(_toMediaItem).toList());
    }
  }

  /// Starts (or restarts) the track at [index]; stays within bounds.
  Future<void> playIndex(int index) async {
    if (_queue.isEmpty) return;
    final clamped = index.clamp(0, _queue.length - 1);
    await _pushIndex(clamped);
  }

  Future<void> _pushIndex(int index) async {
    if (_queue.isEmpty || index < 0 || index >= _queue.length) return;
    _index = index;
    indexNotifier.value = index;
    final track = _queue[index];
    mediaItem.add(_toMediaItem(track));
    await _player.stop();
    final source = track.isLocal
        ? DeviceFileSource(track.url)
        : UrlSource(track.url) as Source;
    await _player.play(source);
    _broadcastPlaybackState(true);
  }

  MediaItem _toMediaItem(MusicTrack track) => MediaItem(
    id: track.id,
    title: track.title,
    artist: track.artist,
    duration: duration.value,
    extras: {'emoji': track.emoji, 'color': track.color.toARGB32()},
  );

  // ── Media session controls (called by the OS media notification) ──────────

  @override
  Future<void> play() async {
    if (_queue.isEmpty) {
      if (_index < _queue.length) return;
      return;
    }
    await _player.resume();
    _broadcastPlaybackState(true);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastPlaybackState(false);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _broadcastPlaybackState(false);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    this.position.value = position;
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    await _pushIndex((_index + 1) % _queue.length);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    await _pushIndex((_index - 1 + _queue.length) % _queue.length);
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

  int get currentIndex => _index;
  List<MusicTrack> get tracks => _queue;

  void _broadcastPlaybackState(bool playing) {
    playbackState.add(
      playbackState.value.copyWith(
        playing: playing,
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  Future<void> disposePlayer() async {
    await _player.dispose();
  }
}
