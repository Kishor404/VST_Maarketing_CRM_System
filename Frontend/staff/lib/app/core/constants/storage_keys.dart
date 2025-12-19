/// Centralized storage keys for GetStorage
/// Used across auth, api client, splash, and profile modules

class StorageKeys {
  StorageKeys._();

  /// =========================
  /// Authentication
  /// =========================
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  /// =========================
  /// User / Profile
  /// =========================
  static const String userProfile = 'user_profile';
  static const String userRole = 'user_role';

  /// =========================
  /// App State
  /// =========================
  static const String isLoggedIn = 'is_logged_in';
  static const String lastSyncAt = 'last_sync_at';
}
