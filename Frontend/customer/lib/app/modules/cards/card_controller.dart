import 'package:get/get.dart';

import '../../data/models/card_model.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/service_repository.dart';

import '../../core/utils/app_snackbar.dart';

class CardController extends GetxController {
  final CardRepository cardRepository;
  final ServiceRepository serviceRepository;

  CardController({
    required this.cardRepository,
    required this.serviceRepository,
  });

  /// -----------------------
  /// UI STATE
  /// -----------------------

  final loading = false.obs;
  bool get isLoading => loading.value;

  final detailLoading = false.obs;

  /// -----------------------
  /// DATA
  /// -----------------------

  final cards = <CardModel>[].obs;
  final selectedCard = Rxn<CardModel>();

  /// All services related to selected card
  final cardServices = <ServiceModel>[].obs;

  /// Convenience getter (completed only)
  List<ServiceModel> get completedServices {
    final list = cardServices
        .where((s) => s.status == 'completed')
        .toList();

    // 🔽 SORT BY DATE (latest first)
    list.sort((a, b) {
      final aDate = a.scheduledAt ?? a.createdAt;
      final bDate = b.scheduledAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return list;
  }

  /// -----------------------
  /// LIFECYCLE
  /// -----------------------

  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  /// -----------------------
  /// ACTIONS
  /// -----------------------

  /// Fetch all cards
  Future<void> loadCards() async {
    try {
      loading.value = true;
      final result = await cardRepository.fetchCards();
      cards.assignAll(result);
      print('✅ Cards loaded: ${cards.length}');
    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to load service cards',
      );
    } finally {
      loading.value = false;
    }
  }

  /// Fetch card detail + related services
  Future<void> loadCardDetail(int cardId) async {
    try {
      detailLoading.value = true;

      /// 1️⃣ Load card
      selectedCard.value =
          await cardRepository.fetchCardDetail(cardId);

      /// 2️⃣ Load all services
      final allServices = await serviceRepository.fetchServices();

      /// 3️⃣ Filter services for this card
      cardServices.assignAll(
        allServices.where((s) => s.cardId == cardId).toList(),
      );

      print(
        '✅ Services for card $cardId: ${cardServices.length}',
      );
    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Failed to load card details',
      );
    } finally {
      detailLoading.value = false;
    }
  }
}
