import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:mind_care_app/features/music/models/music_track.dart';

/// Audio handler backing the platform media session (notification + lock
/// screen -> play / pause / stop / next / previous / seek).
///
/// One instance is registered with [AudioService.init] so the OS keeps a
/// foreground service alive while the queue is playing — this lets the music
/// continue when the app moves to the background instead of being killed.
class CalmAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  List<MusicTrack> _queue = [];
  int _index = 0;

  /// Last state we know the player reached.
  ///
  /// Tracked explicitly (not just via the stream) because a `stop()` on Android
  /// leaves the underlying [android.media.MediaPlayer] unprepared, so the next
  /// `resume()` would throw. We need to know "stopped" to reload instead.
  PlayerState _state = PlayerState.stopped;

  /// True once a track has been loaded, so `play()` knows whether it can
  /// resume or has to start a track from scratch.
  bool _hasTrack = false;

  /// Set while switching tracks so the intermediate `stopped` event from
  /// `stop()` doesn't flicker the UI back to "not playing".
  bool _switching = false;

  /// Throttle baseline for the position notifier; reset whenever the track
  /// changes so a new track's position propagates immediately.
  Duration _lastPos = Duration.zero;

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

    _player.onPositionChanged.listen((d) {
      if ((d - _lastPos).inSeconds.abs() >= 1) {
        _lastPos = d;
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
      final wasPlaying = _state == PlayerState.playing;
      _state = s;
      // Switching tracks emits a transient `stopped` for the old source, and
      // that event can land after the new track already started. Publishing it
      // would flicker the UI back to "not playing".
      if (_switching) return;
      if (s == PlayerState.stopped && wasPlaying) return;
      isPlayingValue.value = s == PlayerState.playing;
      _broadcastPlaybackState(s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) async {
      if (_queue.isEmpty) return;
      await _pushIndex((_index + 1) % _queue.length);
    });
  }

  /// Replaces the playlist shown to the OS media session.
  ///
  /// The current track is preserved by id, so reordering the queue does not
  /// interrupt whatever is playing — the index simply follows the track to its
  /// new position.
  void setQueue(List<MusicTrack> tracks) {
    final currentId = _hasTrack ? _safeTrackAt(_index)?.id : null;
    _queue = List.of(tracks);
    if (_queue.isEmpty) {
      _index = 0;
      return;
    }

    super.queue.add(_queue.map(_toMediaItem).toList());

    // Follow the current track to its new position; if it is gone, stay on the
    // closest valid index instead of pointing past the end of the queue.
    final moved = currentId == null
        ? -1
        : _queue.indexWhere((t) => t.id == currentId);
    final next = moved >= 0 ? moved : _index.clamp(0, _queue.length - 1);
    if (next != _index) {
      _index = next;
      indexNotifier.value = next;
      mediaItem.add(_toMediaItem(_queue[next]));
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
    _resetPosition();
    _switching = true;
    try {
      await _player.stop();
      _hasTrack = true;
      final source = track.isLocal
          ? DeviceFileSource(track.url)
          : UrlSource(track.url) as Source;
      await _player.play(source);
    } finally {
      _switching = false;
    }
    _state = PlayerState.playing;
    isPlayingValue.value = true;
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
    if (_queue.isEmpty || _index < 0 || _index >= _queue.length) return;

    // Android's MediaPlayer is left unprepared by `stop()`, so `resume()` there
    // throws. Reload the track instead — which is also what a user expects
    // from a "play" after "stop": start the track from the beginning.
    if (!_hasTrack ||
        _state == PlayerState.stopped ||
        _state == PlayerState.completed) {
      await _pushIndex(_index);
      return;
    }

    await _player.resume();
    _state = PlayerState.playing;
    isPlayingValue.value = true;
    _broadcastPlaybackState(true);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _state = PlayerState.paused;
    isPlayingValue.value = false;
    _broadcastPlaybackState(false);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _state = PlayerState.stopped;
    isPlayingValue.value = false;
    _resetPosition();
    _broadcastPlaybackState(false);
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_hasTrack) return;
    await _player.seek(position);
    this.position.value = position;
    _lastPos = position;
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

  /// Whether a track is loaded and ready to play or resume.
  bool get hasTrack => _hasTrack;

  /// True when nothing is loaded, paused, or stopped — i.e. pressing play
  /// should (re)start a track rather than resume one.
  bool get isStopped =>
      !_hasTrack ||
      _state == PlayerState.stopped ||
      _state == PlayerState.completed;

  /// Id of the loaded track, or null when nothing has been played yet.
  String? get currentTrackId => _safeTrackAt(_index)?.id;

  MusicTrack? _safeTrackAt(int index) =>
      (index >= 0 && index < _queue.length) ? _queue[index] : null;

  void _resetPosition() {
    _lastPos = Duration.zero;
    position.value = Duration.zero;
  }

  void _broadcastPlaybackState(bool playing) {
    playbackState.add(
      playbackState.value.copyWith(
        playing: playing,
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        // Compact has room for 3: keep prev / play-pause / next here, and let
        // the expanded notification + lock screen surface stop.
        androidCompactActionIndices: const [0, 1, 3],
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  Future<void> disposePlayer() async {
    await _player.dispose();
  }
}
