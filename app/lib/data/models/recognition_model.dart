import 'song_model.dart';

class Recognition {
  final String id;
  final String songId;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final String? coverUrl;
  final String? previewUrl;
  final String? spotifyUrl;
  final String? appleMusicUrl;
  final DateTime recognizedAt;
  final String? locationName;

  const Recognition({
    required this.id,
    required this.songId,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    this.coverUrl,
    this.previewUrl,
    this.spotifyUrl,
    this.appleMusicUrl,
    required this.recognizedAt,
    this.locationName,
  });

  factory Recognition.fromJson(Map<String, dynamic> json) {
    return Recognition(
      id: json['id'] ?? '',
      songId: json['song_id'] ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown',
      album: json['album'],
      genre: json['genre'],
      coverUrl: json['cover_url'],
      previewUrl: json['preview_url'],
      spotifyUrl: json['spotify_url'],
      appleMusicUrl: json['apple_music_url'],
      recognizedAt: DateTime.tryParse(json['recognized_at'] ?? '') ?? DateTime.now(),
      locationName: json['location_name'],
    );
  }

  Song toSong() => Song(
    id: songId,
    title: title,
    artist: artist,
    album: album,
    genre: genre,
    coverUrl: coverUrl,
    previewUrl: previewUrl,
    spotifyUrl: spotifyUrl,
    appleMusicUrl: appleMusicUrl,
  );
}
