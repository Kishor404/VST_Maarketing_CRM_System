import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class CardProvider {
  final ApiClient _apiClient = ApiClient();

  /// -----------------------------
  /// GET /api/crm/cards/
  /// -----------------------------
  Future<List<dynamic>> fetchCards() async {
    final response = await _apiClient.get(
      ApiEndpoints.cards,
    );
    return response.data as List<dynamic>;
  }

  /// -----------------------------
  /// GET /api/crm/cards/{id}/
  /// -----------------------------
  Future<Map<String, dynamic>> fetchCardDetail(int cardId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.cards}$cardId/',
    );
    return response.data as Map<String, dynamic>;
  }
}
