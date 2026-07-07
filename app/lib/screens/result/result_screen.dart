import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/song_model.dart';
import '../../data/providers/song_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final Song song;

  const ResultScreen({super.key, required this.song});

  Future<void> _openUrl(String? url, BuildContext context) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isFav = songProvider.isFavorite(song.id);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Blurred album art background
          if (song.coverUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: song.coverUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.75),
                colorBlendMode: BlendMode.darken,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),

          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.3),
                    AppTheme.background.withValues(alpha: 0.7),
                    AppTheme.background,
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.3, 0.55, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      const Spacer(),
                      if (authProvider.isAuthenticated)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            songProvider.toggleFavorite(song);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isFav
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.04),

                        // Album art
                        Hero(
                          tag: 'album_art_${song.id}',
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: song.coverUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: song.coverUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => _artPlaceholder(),
                                      errorWidget: (_, __, ___) => _artPlaceholder(),
                                    )
                                  : _artPlaceholder(),
                            ),
                          ),
                        ).animate().scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1.0, 1.0),
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ),

                        const SizedBox(height: 32),

                        // Recognized badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'RECOGNIZED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 20),

                        // Song title
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 10),

                        // Artist
                        Text(
                          song.artist,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),

                        if (song.album != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            song.album!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 350.ms),
                        ],

                        const SizedBox(height: 32),

                        // Details chips
                        if (song.releaseDate != null || song.genre != null)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              if (song.releaseDate != null)
                                _chip(Icons.calendar_today_rounded, song.releaseDate!),
                              if (song.genre != null)
                                _chip(Icons.music_note_rounded, song.genre!),
                            ],
                          ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 32),

                        // Streaming section
                        if (song.spotifyUrl != null || song.appleMusicUrl != null) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'LISTEN ON',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (song.spotifyUrl != null)
                            _StreamButton(
                              label: 'Spotify',
                              icon: Icons.music_note_rounded,
                              color: const Color(0xFF1DB954),
                              onTap: () => _openUrl(song.spotifyUrl, context),
                            ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.2, end: 0),
                          if (song.appleMusicUrl != null) ...[
                            const SizedBox(height: 12),
                            _StreamButton(
                              label: 'Apple Music',
                              icon: Icons.apple_rounded,
                              color: const Color(0xFFFC3C44),
                              onTap: () => _openUrl(song.appleMusicUrl, context),
                            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
                          ],
                        ],

                        const SizedBox(height: 32),

                        // Recognize again button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.graphic_eq_rounded),
                            label: const Text('Recognize Another'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(
                                color: AppTheme.primary.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 550.ms),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: AppTheme.cardColor,
      child: const Icon(Icons.music_note_rounded, size: 80, color: AppTheme.primary),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StreamButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StreamButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.7), size: 14),
          ],
        ),
      ),
    );
  }
}
