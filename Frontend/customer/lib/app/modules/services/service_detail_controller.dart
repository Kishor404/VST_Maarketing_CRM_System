import 'package:get/get.dart';
import 'package:vst_maarketing/app/core/utils/app_snackbar.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/service_repository.dart';

class ServiceDetailController extends GetxController {
  final ServiceRepository serviceRepository;

  ServiceDetailController({
    required this.serviceRepository,
  });

  final loading = true.obs;
  final service = Rxn<ServiceModel>();

  late final int serviceId;

  @override
  void onInit() {
    super.onInit();
    serviceId = Get.arguments as int;
    loadServiceDetail();
  }

  Future<void> loadServiceDetail() async {
    try {
      loading.value = true;
      service.value =
          await serviceRepository.fetchServiceDetail(serviceId);
    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to load service details',
      );
    } finally {
      loading.value = false;
    }
  }

  /// 🔄 Used after feedback submission
  Future<void> reloadService() async {
    await loadServiceDetail();
  }
}
