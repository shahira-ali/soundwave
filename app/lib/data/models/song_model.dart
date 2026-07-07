class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? releaseDate;
  final String? genre;
  final String? coverUrl;
  final String? previewUrl;
  final String? spotifyUrl;
  final String? appleMusicUrl;
  final String? youtubeUrl;
  final int? score;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.releaseDate,
    this.genre,
    this.coverUrl,
    this.previewUrl,
    this.spotifyUrl,
    this.appleMusicUrl,
    this.youtubeUrl,
    this.score,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'],
      releaseDate: json['release_date'],
      genre: json['genre'],
      coverUrl: json['cover_url'],
      previewUrl: json['preview_url'],
      spotifyUrl: json['spotify_url'],
      appleMusicUrl: json['apple_music_url'],
      youtubeUrl: json['youtube_url'],
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'release_date': releaseDate,
    'genre': genre,
    'cover_url': coverUrl,
    'preview_url': previewUrl,
    'spotify_url': spotifyUrl,
    'apple_music_url': appleMusicUrl,
    'youtube_url': youtubeUrl,
  };
}
