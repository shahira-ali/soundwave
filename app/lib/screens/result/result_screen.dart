import 'package:flutter/material.dart';
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
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open link")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isFav = songProvider.isFavorite(song.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (authProvider.isAuthenticated)
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () => songProvider.toggleFavorite(song),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (song.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: song.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.cardColor),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.cardColor,
                          child: const Icon(Icons.music_note, size: 80, color: AppTheme.primary)),
                    )
                  else
                    Container(
                      color: AppTheme.cardColor,
                      child: const Icon(Icons.music_note, size: 80, color: AppTheme.primary),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.background.withValues(alpha: 0.9)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recognized badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Recognized', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    song.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    song.artist,
                    style: const TextStyle(fontSize: 20, color: AppTheme.primary, fontWeight: FontWeight.w500),
                  ).animate().fadeIn(delay: 200.ms),
                  if (song.album != null) ...[
                    const SizedBox(height: 4),
                    Text(song.album!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16))
                        .animate().fadeIn(delay: 250.ms),
                  ],
                  const SizedBox(height: 32),
                  // Details grid
                  _buildDetailsGrid(),
                  const SizedBox(height: 32),
                  // Action buttons
                  const Text('Listen on', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  _buildStreamingButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    final details = <Map<String, String>>[];
    if (song.releaseDate != null) details.add({'label': 'Released', 'value': song.releaseDate!});
    if (song.genre != null) details.add({'label': 'Genre', 'value': song.genre!});

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: details.map((d) => Expanded(
          child: Column(
            children: [
              Text(d['label']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(d['value']!, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildStreamingButtons(BuildContext context) {
    return Column(
      children: [
        if (song.spotifyUrl != null)
          _StreamingButton(
            label: 'Spotify',
            icon: Icons.music_note,
            color: const Color(0xFF1DB954),
            onTap: () => _openUrl(song.spotifyUrl, context),
          ),
        if (song.appleMusicUrl != null) ...[
          const SizedBox(height: 10),
          _StreamingButton(
            label: 'Apple Music',
            icon: Icons.apple,
            color: const Color(0xFFFC3C44),
            onTap: () => _openUrl(song.appleMusicUrl, context),
          ),
        ],
        if (song.spotifyUrl == null && song.appleMusicUrl == null)
          const Text('No streaming links available', style: TextStyle(color: AppTheme.textSecondary)),
      ],
    ).animate().fadeIn(delay: 350.ms);
  }
}

class _StreamingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StreamingButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
