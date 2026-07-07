import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/song_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/song_card.dart';
import '../result/result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<SongProvider>().loadFavorites();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<SongProvider>().search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Favorites')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<SongProvider>().clearSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: songProvider.searchLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : songProvider.searchQuery != null
                    ? _buildSearchResults(songProvider, authProvider)
                    : _buildFavorites(songProvider, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SongProvider provider, AuthProvider auth) {
    if (provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text('No results for "${provider.searchQuery}"', style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.searchResults.length,
      itemBuilder: (_, i) {
        final song = provider.searchResults[i];
        return SongCard(
          song: song,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(song: song))),
          trailing: auth.isAuthenticated
              ? IconButton(
                  icon: Icon(
                    provider.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
                    color: provider.isFavorite(song.id) ? Colors.redAccent : AppTheme.textSecondary,
                  ),
                  onPressed: () => provider.toggleFavorite(song),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFavorites(SongProvider provider, AuthProvider auth) {
    if (!auth.isAuthenticated) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('Sign in to see your favorites', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (provider.favoritesLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (provider.favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('No favorites yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('Heart a song on its detail page to save it here', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text('Your Favorites', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.favorites.length,
            itemBuilder: (_, i) {
              final song = provider.favorites[i];
              return SongCard(
                song: song,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(song: song))),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.redAccent),
                  onPressed: () => provider.toggleFavorite(song),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
