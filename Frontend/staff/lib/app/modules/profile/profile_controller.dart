import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/snackbar.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final GetStorage _storage = GetStorage();

  final loading = false.obs;

  // Profile fields
  final name = ''.obs;
  final phone = ''.obs;
  final role = ''.obs;
  final region = ''.obs;
  final address=''.obs;
  final id = ''.obs;
  final isAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      loading.value = true;

      /// ✅ ApiClient returns MAP directly
      final data =
          await _apiClient.get(ApiEndpoints.myProfile);

      print(data);

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid profile response');
      }

      name.value = data['name'] ?? '';
      phone.value = data['phone'] ?? '';
      role.value = data['role'] ?? '';
      address.value = data['address']!="" ? "${data['address']}, ${data['city']}" :"No Address Set";
      region.value = data['region'] ?? '';
      id.value = data['id'].toString();
      isAvailable.value = data['is_available'] ?? false;

      // Cache
      _storage.write(StorageKeys.userProfile, data);
      _storage.write(StorageKeys.userRole, role.value);
    } catch (e) {
      AppSnackbar.error(
        title: 'Profile Error',
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }

  void logout() {
    _storage.erase();
    Get.offAllNamed(AppRoutes.login);
  }
}
