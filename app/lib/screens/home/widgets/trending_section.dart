import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/providers/recognition_provider.dart';
import '../../../data/models/song_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../result/result_screen.dart';

class TrendingSection extends StatelessWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecognitionProvider>(
      builder: (_, provider, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: AppTheme.accent, size: 20),
                  SizedBox(width: 8),
                  Text('Trending This Week',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (provider.trendingLoading)
              _buildShimmer()
            else if (provider.trending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('No trending songs yet. Start recognizing music!',
                    style: TextStyle(color: AppTheme.textSecondary)),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.trending.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _TrendingCard(song: provider.trending[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppTheme.cardColor,
          highlightColor: AppTheme.surface,
          child: Container(
            width: 130,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Song song;
  const _TrendingCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(song: song))),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: song.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.coverUrl!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(height: 110, color: AppTheme.surface),
                      errorWidget: (_, __, ___) => Container(
                        height: 110,
                        color: AppTheme.surface,
                        child: const Icon(Icons.music_note, color: AppTheme.primary, size: 36),
                      ),
                    )
                  : Container(
                      height: 110,
                      color: AppTheme.surface,
                      child: const Icon(Icons.music_note, color: AppTheme.primary, size: 36),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(song.artist, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
