import 'package:get/get.dart';

import '../../data/models/job_card_model.dart';
import '../../data/providers/job_card_provider.dart';
import '../../core/utils/snackbar.dart';

class JobCardController extends GetxController {
  final JobCardProvider _provider = JobCardProvider();

  /// ==============================
  /// STATE
  /// ==============================

  final loading = false.obs;
  final reinstallLoading = false.obs;

  /// My created job cards
  final myJobCards = <JobCardModel>[].obs;

  /// Reinstall pending job cards
  final reinstallJobCards = <JobCardModel>[].obs;

  /// Selected Job Card (detail page)
  final selectedJobCard = Rxn<JobCardModel>();

  /// OTP (for reinstall)
  final otp = ''.obs;

  /// ==============================
  /// INIT
  /// ==============================

  @override
  void onInit() {
    super.onInit();
    loadJobCards();
  }

  /// ==============================
  /// LOAD ALL JOB CARDS
  /// ==============================

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
        title: "Job Cards Error",
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }

  /// ==============================
  /// REFRESH SINGLE LISTS
  /// ==============================

  Future<void> refreshMyJobCards() async {
    try {
      final data = await _provider.getMyJobCards();
      myJobCards.assignAll(data);
    } catch (e) {
      AppSnackbar.error(title: "Error", message: e.toString());
    }
  }

  Future<void> refreshReinstallCards() async {
    try {
      final data = await _provider.getReinstallJobCards();
      reinstallJobCards.assignAll(data);
    } catch (e) {
      AppSnackbar.error(title: "Error", message: e.toString());
    }
  }

  /// ==============================
  /// LOAD DETAIL
  /// ==============================

  Future<void> loadDetail(int jobCardId) async {
    try {
      selectedJobCard.value =
          await _provider.getJobCardDetail(jobCardId);
    } catch (e) {
      AppSnackbar.error(
        title: "Detail Error",
        message: e.toString(),
      );
    }
  }

  /// ==============================
  /// REINSTALL PART
  /// ==============================

  Future<void> reinstallPart({
    required int serviceId,
    required int jobCardId,
    required String otp,
  }) async {
    try {
      reinstallLoading.value = true;

      await _provider.reinstallPart(
        serviceId: serviceId,
        jobCardIds: [jobCardId],
        otp: otp,
      );

      /// refresh lists
      await loadJobCards();

      AppSnackbar.success(
        title: "Reinstalled",
        message: "Part reinstalled successfully",
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

  /// ==============================
  /// BULK REINSTALL
  /// ==============================

  Future<void> reinstallMultiple({
    required int serviceId,
    required List<int> jobCardIds,
    required String otp,
  }) async {
    try {
      reinstallLoading.value = true;

      await _provider.reinstallPart(
        serviceId: serviceId,
        jobCardIds: jobCardIds,
        otp: otp,
      );

      await loadJobCards();

      AppSnackbar.success(
        title: "Reinstalled",
        message: "Selected parts reinstalled",
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

  /// ==============================
  /// COUNTERS (For Navbar Badge)
  /// ==============================

  int get myCount => myJobCards.length;

  int get reinstallCount => reinstallJobCards.length;

}
