import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';

class SongProvider extends ChangeNotifier {
  List<Song> _searchResults = [];
  List<Song> _favorites = [];
  Set<String> _favoritedIds = {};
  bool _searchLoading = false;
  bool _favoritesLoading = false;
  String? _searchQuery;

  List<Song> get searchResults => _searchResults;
  List<Song> get favorites => _favorites;
  bool get searchLoading => _searchLoading;
  bool get favoritesLoading => _favoritesLoading;
  String? get searchQuery => _searchQuery;

  bool isFavorite(String songId) => _favoritedIds.contains(songId);

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _searchLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.searchSongs(query);
      if (res['success'] == true) {
        _searchResults = (res['data']['songs'] as List).map((e) => Song.fromJson(e)).toList();
      }
    } catch (_) {}

    _searchLoading = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchQuery = null;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _favoritesLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getFavorites();
      if (res['success'] == true) {
        _favorites = (res['data']['songs'] as List).map((e) => Song.fromJson(e)).toList();
        _favoritedIds = _favorites.map((s) => s.id).toSet();
      }
    } catch (_) {}

    _favoritesLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    if (_favoritedIds.contains(song.id)) {
      _favoritedIds.remove(song.id);
      _favorites.removeWhere((s) => s.id == song.id);
      notifyListeners();
      await ApiService.removeFavorite(song.id);
    } else {
      _favoritedIds.add(song.id);
      _favorites.insert(0, song);
      notifyListeners();
      await ApiService.addFavorite(song.id);
    }
  }
}
