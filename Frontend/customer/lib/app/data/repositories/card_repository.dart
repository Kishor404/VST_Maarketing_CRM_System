import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../../core/api/api_client.dart';


class CardRepository {
  final CardProvider provider;
  final ApiClient apiClient = ApiClient();


  CardRepository(this.provider);

  /// -----------------------------
  /// Fetch all cards
  /// -----------------------------
  Future<List<CardModel>> fetchCards() async {
    final List<dynamic> data = await provider.fetchCards();

    return data
        .map((json) => CardModel.fromJson(json))
        .toList();
  }

  /// -----------------------------
  /// Fetch single card detail
  /// -----------------------------
  Future<CardModel> fetchCardDetail(int cardId) async {
    final Map<String, dynamic> data =
        await provider.fetchCardDetail(cardId);

    return CardModel.fromJson(data);
  }

  Future<Map<String, dynamic>> fetchWarrantyReport(int cardId) async {
    final res = await apiClient.get(
      '/api/crm/reports/warranty-report/by_card/',
      queryParameters: { 'card_id': cardId },
    );
    return res.data;
  }

}
