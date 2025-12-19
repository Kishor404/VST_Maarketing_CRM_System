import 'package:get/get.dart';
import 'package:vst_maarketing/app/core/utils/app_snackbar.dart';

import '../../data/models/card_model.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../routes/app_routes.dart';

class ServiceBookingController extends GetxController {
  final CardRepository cardRepository;
  final ServiceRepository serviceRepository;

  ServiceBookingController({
    required this.cardRepository,
    required this.serviceRepository,
  });

  /// -----------------------------
  /// UI State
  /// -----------------------------
  final cards = <CardModel>[].obs;
  final selectedCard = Rxn<CardModel>();

  final complaint = ''.obs;
  final preferredDate = Rxn<DateTime>();

  final loading = false.obs;
  final submitting = false.obs;

  final complaintType = RxnString();
  final customComplaint = ''.obs;

  final List<String> complaintOptions = [
    'Water leakage',
    'Water taste bad',
    'Low water flow',
    'Filter replacement',
    'Other',
  ];


  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  /// -----------------------------
  /// Load customer cards
  /// -----------------------------
  Future<void> loadCards() async {
    try {
      loading.value = true;
      final result = await cardRepository.fetchCards();
      cards.assignAll(result);
    } catch (_) {
      AppSnackbar.error('Error', 'Failed to load service cards');
    } finally {
      loading.value = false;
    }
  }

  /// -----------------------------
  /// Submit booking
  /// -----------------------------
  Future<void> submitBooking() async {
    if (selectedCard.value == null) {
      AppSnackbar.error('Validation', 'Please select a service card');
      return;
    }

    if (complaint.value.trim().isEmpty) {
      AppSnackbar.error('Validation', 'Please enter complaint details');
      return;
    }

    if (preferredDate.value == null) {
      AppSnackbar.error('Validation', 'Please select preferred date');
      return;
    }

    try {
      submitting.value = true;

      await serviceRepository.bookService(
        cardId: selectedCard.value!.id,
        description: complaint.value.trim(),
        preferredDate: preferredDate.value!,
      );

      AppSnackbar.success(
        'Success',
        'Service booked successfully',
      );

      /// Redirect to service list
      Get.offNamedUntil(
        AppRoutes.SERVICES,
        (route) => route.settings.name == AppRoutes.HOME,
      );


    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to book service',
      );
    } finally {
      submitting.value = false;
    }
  }
}
