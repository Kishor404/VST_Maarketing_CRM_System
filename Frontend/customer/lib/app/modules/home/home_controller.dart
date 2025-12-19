import 'package:get/get.dart';
import 'package:vst_maarketing/app/core/utils/app_snackbar.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../routes/app_routes.dart';

import "../../data/models/next_service_model.dart";

class HomeController extends GetxController {
  final AuthRepository authRepository;
  final CardRepository cardRepository;
  final ServiceRepository serviceRepository;

  final nextServices = <NextServiceModel>[].obs;

  HomeController({
    required this.authRepository,
    required this.cardRepository,
    required this.serviceRepository,
  });

  /// -------------------------
  /// UI STATE
  /// -------------------------
  final loading = false.obs;

  /// -------------------------
  /// DASHBOARD DATA
  /// -------------------------
  final userName = ''.obs;
  final cardCount = 0.obs;
  final activeServiceCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadNextFreeServices() async {
    final cards = await cardRepository.fetchCards();
    final now = DateTime.now();

    final List<NextServiceModel> upcoming = [];

    for (final card in cards) {
      final report =
          await cardRepository.fetchWarrantyReport(card.id);

      final milestones = report['milestones'] as List;

      final futureDates = milestones
          .where((m) => m['status'] == 'notdone')
          .map((m) => DateTime.parse(m['milestone']))
          .where((d) => d.isAfter(now))
          .toList()
        ..sort();

      if (futureDates.isNotEmpty) {
        upcoming.add(
          NextServiceModel(
            cardId: card.id,
            cardModel: report['card_model'],
            nextServiceDate: futureDates.first,
          ),
        );
      }
    }

    upcoming.sort(
      (a, b) => a.nextServiceDate.compareTo(b.nextServiceDate),
    );

    nextServices.assignAll(upcoming);
  }


  /// -------------------------
  /// LOAD DASHBOARD
  /// -------------------------
  Future<void> loadDashboard() async {
    try {
      loading.value = true;

      /// 1️⃣ User profile
      final user = await authRepository.getProfile();
      userName.value = user.name;

      /// 2️⃣ Cards
      final cards = await cardRepository.fetchCards();
      cardCount.value = cards.length;

      await loadNextFreeServices();

      /// 3️⃣ Services
      final services = await serviceRepository.fetchServices();
      activeServiceCount.value = services
          .where((s) =>
              s.status == 'pending' ||
              s.status == 'assigned' ||
              s.status == 'awaiting_otp')
          .length;
    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to load dashboard data',
      );
    } finally {
      loading.value = false;
    }
  }

  /// -------------------------
  /// BOOK SERVICE (LOGIC ONLY)
  /// -------------------------
  void openServiceBookingFromHome() {

      Get.toNamed(
        AppRoutes.SERVICE_BOOK,
      );
      return;
  }

  /// -------------------------
  /// REFRESH
  /// -------------------------
  Future<void> refreshDashboard() async {
    await loadDashboard();
  }
}
