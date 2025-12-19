import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vst_maarketing/app/core/utils/app_snackbar.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final AuthRepository authRepository;
  final GetStorage _storage = GetStorage();

  ProfileController({required this.authRepository});

  final loading = true.obs;
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  /// Load logged-in user profile
  Future<void> loadProfile() async {
    try {
      loading.value = true;
      user.value = await authRepository.getProfile();
    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to load profile',
      );
    } finally {
      loading.value = false;
    }
  }

  /// Logout user
  void logout() {
    _storage.erase();
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
