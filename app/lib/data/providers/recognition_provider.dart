import 'dart:io';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/recognition_model.dart';
import '../services/api_service.dart';

enum RecognitionState { idle, listening, processing, found, notFound, error }

class RecognitionProvider extends ChangeNotifier {
  RecognitionState _state = RecognitionState.idle;
  Song? _recognizedSong;
  List<Recognition> _history = [];
  List<Song> _trending = [];
  bool _historyLoading = false;
  bool _trendingLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;

  RecognitionState get state => _state;
  Song? get recognizedSong => _recognizedSong;
  List<Recognition> get history => _history;
  List<Song> get trending => _trending;
  bool get historyLoading => _historyLoading;
  bool get trendingLoading => _trendingLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreHistory => _currentPage < _totalPages;

  Future<void> recognize(File audioFile) async {
    _state = RecognitionState.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.recognizeSong(audioFile);
      if (res['success'] == true) {
        _recognizedSong = Song.fromJson(res['data']['song']);
        _state = RecognitionState.found;
      } else {
        _errorMessage = res['message'] ?? 'Song not recognized';
        _state = RecognitionState.notFound;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _state = RecognitionState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = RecognitionState.idle;
    _recognizedSong = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _history = [];
    }
    _historyLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getHistory(page: _currentPage);
      if (res['success'] == true) {
        final items = (res['data']['recognitions'] as List)
            .map((e) => Recognition.fromJson(e))
            .toList();
        if (refresh) {
          _history = items;
        } else {
          _history.addAll(items);
        }
        final pagination = res['data']['pagination'];
        _totalPages = pagination['totalPages'];
        _currentPage++;
      }
    } catch (_) {}

    _historyLoading = false;
    notifyListeners();
  }

  Future<void> deleteHistoryItem(String id) async {
    await ApiService.deleteHistoryItem(id);
    _history.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> loadTrending() async {
    _trendingLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getTrending();
      if (res['success'] == true) {
        _trending = (res['data']['songs'] as List).map((e) => Song.fromJson(e)).toList();
      }
    } catch (_) {}

    _trendingLoading = false;
    notifyListeners();
  }
}
