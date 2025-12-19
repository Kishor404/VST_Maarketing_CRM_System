import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthProvider provider;

  AuthRepository(this.provider);

  /// -----------------------------
  /// LOGIN
  /// -----------------------------
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final data = await provider.login(
      phone: phone,
      password: password,
    );

    // data already contains access & refresh tokens
    return data;
  }

  /// -----------------------------
  /// REGISTER
  /// -----------------------------
  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String address,
    required String city,
    required String postalCode,
    required String region,
  }) async {
    await provider.register(
      name: name,
      phone: phone,
      password: password,
      address: address,
      city: city,
      postalCode: postalCode,
      region: region,
    );
  }

  /// -----------------------------
  /// PROFILE
  /// -----------------------------
  Future<UserModel> getProfile() async {
    final data = await provider.getProfile();
    return UserModel.fromJson(data);
  }
}
