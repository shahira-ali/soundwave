class AppConstants {
  // Change this to your backend URL
  // For Android emulator use: http://10.0.2.2:3000
  // For iOS simulator use: http://localhost:3000
  // For physical device use your machine's local IP: http://192.168.x.x:3000
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static const String authToken = 'auth_token';
  static const String userKey = 'current_user';

  static const Duration recordingDuration = Duration(seconds: 10);
  static const int maxHistoryPerPage = 20;

  static const String appName = 'Soundwave';
  static const String appTagline = 'Discover the music around you';
}
