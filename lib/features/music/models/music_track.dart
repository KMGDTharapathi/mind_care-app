import 'package:flutter/material.dart';

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

final List<MusicTrack> kDefaultTracks = [
  const MusicTrack(
    id: 'clair_de_lune',
    title: 'Clair de Lune',
    artist: 'Debussy',
    emoji: '🌙',
    color: Color(0xFF5C6BC0),
    url:
        'https://archive.org/download/clair-de-lune_202408/clair%20de%20lune.mp3',
  ),
  const MusicTrack(
    id: 'moonlight_sonata',
    title: 'Moonlight Sonata',
    artist: 'Beethoven',
    emoji: '🌌',
    color: Color(0xFF3949AB),
    url:
        'https://archive.org/download/MoonlightSonata_755/Beethoven-MoonlightSonata.mp3',
  ),
  const MusicTrack(
    id: 'gymnopedie',
    title: 'Gymnopédie No. 1',
    artist: 'Satie',
    emoji: '🌿',
    color: Color(0xFF43A047),
    url:
        'https://archive.org/download/erik-satie-gymnopedie-no.-1_202211/Erik%20Satie%20-%20Gymnop%C3%A9die%20No.1.mp3',
  ),
  const MusicTrack(
    id: 'canon_in_d',
    title: 'Canon in D',
    artist: 'Pachelbel',
    emoji: '🎻',
    color: Color(0xFF00897B),
    url:
        'https://archive.org/download/canon-in-d-major-piano-orchestra_202603/Canon%20In%20D%20Major%20%28Piano-Orchestra%29.mp3',
  ),
  const MusicTrack(
    id: 'fur_elise',
    title: 'Für Elise',
    artist: 'Beethoven',
    emoji: '🎹',
    color: Color(0xFF8E24AA),
    url:
        'https://archive.org/download/beethoven-fur-elise/Beethoven%20-%20F%C3%BCr%20Elise%20.mp3',
  ),
  const MusicTrack(
    id: 'nocturne_op9',
    title: 'Nocturne Op. 9 No. 2',
    artist: 'Chopin',
    emoji: '🕊️',
    color: Color(0xFF00897B),
    url:
        'https://archive.org/download/nocturneineflatmajorop.9no.2/Nocturne%20in%20E%20flat%20major%2C%20Op.%209%20no.%202.mp3',
  ),
];
