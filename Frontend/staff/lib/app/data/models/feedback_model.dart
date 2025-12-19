class FeedbackModel {
  final int id;
  final int rating;
  final String? comments;
  final int customer;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.rating,
    this.comments,
    required this.customer,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      rating: json['rating'],
      comments: json['comments'],
      customer: json['customer'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// 🔥 UI-safe getters
  String get customerLabel => 'Customer #$customer';

  String get createdAtFormatted =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}
