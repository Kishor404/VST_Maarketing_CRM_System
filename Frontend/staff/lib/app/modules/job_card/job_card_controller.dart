import 'package:get/get.dart';
import '../../data/models/job_card_model.dart';
import '../../data/providers/job_card_provider.dart';
import '../../core/utils/snackbar.dart';

class JobCardController extends GetxController {
  final JobCardProvider _provider = JobCardProvider();

  final loading = false.obs;
  final reinstallLoading = false.obs;

  final myJobCards = <JobCardModel>[].obs;
  final reinstallJobCards = <JobCardModel>[].obs;

  final selectedJobCard = Rxn<JobCardModel>();

  final otp = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadJobCards();
  }

  /// ==============================
  /// LOAD STAFF JOB CARDS
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
        title: "Job Card Error",
        message: e.toString(),
      );
    } finally {
      loading.value = false;
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
        title: "Error",
        message: e.toString(),
      );
    }
  }

  /// ==============================
  /// SINGLE REINSTALL
  /// ==============================
  Future<void> reinstallSingle({
    required JobCardModel jobCard,
    required String otp,
  }) async {
    try {
      reinstallLoading.value = true;

      await _provider.reinstallPart(
        serviceId: jobCard.serviceId,
        jobCardIds: [jobCard.id],
        otp: otp,
      );

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
        title: "Success",
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
  /// COUNTERS (NAV BAR)
  /// ==============================
  int get myCount => myJobCards.length;
  int get reinstallCount =>
      reinstallJobCards.where((e) => e.isRepairCompleted).length;
}
