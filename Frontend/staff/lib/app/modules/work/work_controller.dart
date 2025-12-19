import 'package:get/get.dart';

import '../../data/models/service_model.dart';
import '../../data/providers/service_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/snackbar.dart';

class WorkController extends GetxController {
  final ServiceProvider _provider = ServiceProvider(ApiClient());

  final assignedServices = <ServiceModel>[].obs;
  final completedServices = <ServiceModel>[].obs;

  final selectedService = Rxn<ServiceModel>();

  /// Loading states
  final loading = false.obs;
  final detailLoading = false.obs;
  final otpLoading = false.obs;

  final workDetail = ''.obs;
  final amountCharged = ''.obs;
  final otp = ''.obs;
  final partsReplaced = <String>[].obs;

  final phone = ''.obs;

  

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  /// ============================
  /// Load Assigned + Completed
  /// ============================
  Future<void> loadAll() async {
    try {
      loading.value = true;

      final results = await Future.wait([
        _provider.getAssignedServices(),
        _provider.getCompletedServices(),
      ]);

      assignedServices.assignAll(results[0]);
      completedServices.assignAll(results[1]);
    } catch (e) {
      AppSnackbar.error(
        title: "Work Error",
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }

  /// ============================
  /// Service Detail
  /// ============================
  Future<void> loadDetail(int id) async {
    try {
      detailLoading.value = true;
      selectedService.value =
          await _provider.getServiceDetail(id);
    } catch (e) {
      AppSnackbar.error(
        title: "Detail Error",
        message: e.toString(),
      );
    } finally {
      detailLoading.value = false;
    }
  }

  /// ============================
  /// OTP Request
  /// ============================
  Future<void> requestOtp(int serviceId) async {
    if (phone.value.length != 10) {
      AppSnackbar.error(
        title: "Invalid Phone",
        message: "Enter a valid 10-digit phone number",
      );
      return;
    }

    try {
      otpLoading.value = true;

      final fullPhone = "+91${phone.value}";

      await _provider.requestOtp(
        serviceId,
        phone: fullPhone,
      );

      AppSnackbar.success(
        title: "OTP Sent",
        message: "OTP sent to $fullPhone",
      );
    } catch (e) {
      AppSnackbar.error(
        title: "OTP Error",
        message: e.toString(),
      );
    } finally {
      otpLoading.value = false;
    }
  }


  /// ============================
  /// Complete Service
  /// ============================
  Future<void> completeService({
    required int serviceId,
    required String otp,
    required Map<String, dynamic> payload,
  }) async {
    try {
      otpLoading.value = true;
      print(payload);
      await _provider.verifyOtpAndComplete(
        serviceId: serviceId,
        otp: otp,
        payload: payload,
      );

      /// ✅ Reset local state
      selectedService.value = null;
      workDetail.value = '';
      amountCharged.value = '';
      otp = '';
      partsReplaced.clear();

      /// ✅ Refresh data
      await loadAll(); // fetchAssigned + fetchCompleted

      /// ✅ Close ONLY the completion page
      Get.back();
      Get.back();

      AppSnackbar.success(
        title: "Completed",
        message: "Service completed successfully",
      );
    } catch (e) {
      AppSnackbar.error(
        title: "Completion Failed",
        message: e.toString(),
      );
    } finally {
      otpLoading.value = false;
    }
  }

  int get assignedCount => assignedServices.length;

}
