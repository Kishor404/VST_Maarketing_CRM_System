import '../models/service_model.dart';
import '../providers/service_provider.dart';

class ServiceRepository {
  final ServiceProvider provider;

  ServiceRepository(this.provider);

  /// -----------------------------
  /// Fetch all services (List page)
  /// -----------------------------
  Future<List<ServiceModel>> fetchServices() async {
    final List<dynamic> data = await provider.fetchServices();

    return data
        .map((json) => ServiceModel.fromJson(json))
        .toList();
  }

  /// -----------------------------
  /// Fetch single service detail
  /// -----------------------------
  Future<ServiceModel> fetchServiceDetail(int serviceId) async {
    final Map<String, dynamic> data =
        await provider.fetchServiceDetail(serviceId);

    return ServiceModel.fromJson(data);
  }

  /// -----------------------------
  /// Book a new service
  /// -----------------------------
  Future<void> bookService({
    required int cardId,
    required String description,
    required DateTime preferredDate,
  }) async {
    await provider.bookService(
      cardId: cardId,
      description: description,
      preferredDate: preferredDate,
    );
  }
}
