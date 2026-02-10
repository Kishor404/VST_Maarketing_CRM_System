import 'package:get/get.dart';
import '../../data/models/job_card_model.dart';
import '../../data/providers/job_card_provider.dart';
import '../../core/utils/snackbar.dart';

class JobCardController extends GetxController {
  final JobCardProvider _provider = JobCardProvider();

  final loading = false.obs;
  final reinstallLoading = false.obs;
  final devOtp = ''.obs;

  final myJobCards = <JobCardModel>[].obs;
  final reinstallJobCards = <JobCardModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadJobCards();
  }

  @override
  void onClose() {
    devOtp.value = '';
    super.onClose();
  }

  Future<void> loadJobCards() async {
    try {
      loading.value = true;

      final results = await Future.wait([
        _provider.getMyJobCards(),
        _provider.getReinstallJobCards(),
      ]);

      myJobCards.assignAll(results[0]);
      reinstallJobCards.assignAll(results[1]);

    } catch (e) {
      AppSnackbar.error(
        title: "Job Card Error",
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> reinstallSingle({
    required JobCardModel jobCard,
    required String otp,
  }) async {

    try {
      reinstallLoading.value = true;

      final response = await _provider.reinstallPart(
        serviceId: jobCard.serviceId,
        jobCardIds: [jobCard.id],
        otp: otp,
      );

      /// ⭐ DEV OTP SUPPORT
      if (response["otp"] != null) {
        devOtp.value = response["otp"].toString();
      } else {
        devOtp.value = '';
      }

      await loadJobCards();

      AppSnackbar.success(
        title: "Success",
        message: "Part reinstalled",
      );

    } catch (e) {
      AppSnackbar.error(
        title: "Reinstall Failed",
        message: e.toString(),
      );
    } finally {
      reinstallLoading.value = false;
    }
  }

  /// -----------------------------
  /// REQUEST OTP
  /// -----------------------------
  Future<void> requestReinstallOtp(int jobCardId) async {
    try {
      reinstallLoading.value = true;

      final otp = await _provider.requestReinstallOtp(jobCardId);

      if (otp != null) {
        devOtp.value = otp; // DEV ONLY
      }

      AppSnackbar.success(
        title: "OTP Sent",
        message: "OTP sent to customer",
      );
    } catch (e) {
      AppSnackbar.error(title: "OTP Error", message: e.toString());
    } finally {
      reinstallLoading.value = false;
    }
  }

  /// -----------------------------
  /// VERIFY OTP
  /// -----------------------------
  Future<void> verifyReinstallOtp({
    required JobCardModel jobCard,
    required String otp,
  }) async {
    try {
      reinstallLoading.value = true;

      await _provider.verifyReinstallOtp(
        jobCardId: jobCard.id,
        otp: otp,
      );

      devOtp.value = '';
      await loadJobCards();

      AppSnackbar.success(
        title: "Success",
        message: "Part reinstalled successfully",
      );
    } catch (e) {
      AppSnackbar.error(title: "Failed", message: e.toString());
    } finally {
      reinstallLoading.value = false;
    }
  }


  int get reinstallCount =>
      reinstallJobCards.where((e) => e.isRepairCompleted).length;
}
