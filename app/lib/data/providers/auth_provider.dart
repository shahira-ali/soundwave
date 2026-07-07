import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: AppConstants.authToken);
    if (token == null) return;

    try {
      final userData = await _storage.read(key: AppConstants.userKey);
      if (userData != null) {
        _user = User.fromJson(jsonDecode(userData));
        notifyListeners();
      }
      // Verify token is still valid
      final res = await ApiService.getMe();
      if (res['success'] == true) {
        _user = User.fromJson(res['data']['user']);
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
        notifyListeners();
      } else {
        await logout();
      }
    } catch (_) {
      await logout();
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.register(username: username, email: email, password: password);
      if (res['success'] == true) {
        final token = res['data']['token'] as String;
        _user = User.fromJson(res['data']['user']);
        await _storage.write(key: AppConstants.authToken, value: token);
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _error = res['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return _error;
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<String?> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.login(email: email, password: password);
      if (res['success'] == true) {
        final token = res['data']['token'] as String;
        _user = User.fromJson(res['data']['user']);
        await _storage.write(key: AppConstants.authToken, value: token);
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _error = res['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return _error;
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: AppConstants.authToken);
    await _storage.delete(key: AppConstants.userKey);
    notifyListeners();
  }
}
