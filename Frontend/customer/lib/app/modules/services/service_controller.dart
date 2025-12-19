import 'package:get/get.dart';
import 'package:vst_maarketing/app/core/utils/app_snackbar.dart';

import '../../data/models/service_model.dart';
import '../../data/repositories/service_repository.dart';

class ServiceController extends GetxController {
  final ServiceRepository serviceRepository;

  ServiceController({required this.serviceRepository});

  /// UI state
  final loading = false.obs;

  /// Services list
  final services = <ServiceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  /// Fetch all services for logged-in customer
  Future<void> loadServices() async {
    try {
      loading.value = true;
      services.assignAll(await serviceRepository.fetchServices());
      services.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );
    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to load services',
      );
    } finally {
      loading.value = false;
    }
  }

  /// Refresh
  Future<void> refreshServices() async {
    await loadServices();
  }

  /// ---------------------------
  /// BOOK SERVICE (FIXED)
  /// ---------------------------
  Future<void> bookService({
    required int cardId,
    required String description,
    required DateTime preferredDate,
    required String preferredTime,
  }) async {
    try {
      loading.value = true;

      await serviceRepository.bookService(
        cardId: cardId,
        description: description,
        preferredDate: preferredDate,
      );

      AppSnackbar.success(
        'Success',
        'Service booked successfully',
      );

      // ✅ Go back to previous page (My Services)
      Get.back(result: true);

    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to book service',
      );
    } finally {
      loading.value = false;
    }
  }
}