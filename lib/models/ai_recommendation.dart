import 'menu_item.dart';

class AiRecommendationItem {
  final MenuItem menuItem;
  final String reason;

  AiRecommendationItem({
    required this.menuItem,
    required this.reason,
  });

  factory AiRecommendationItem.fromJson(Map<String, dynamic> json) {
    return AiRecommendationItem(
      menuItem: MenuItem.fromJson(json),
      reason: json['reason'] ?? '',
    );
  }
}

class AiRecommendation {
  final String title;
  final List<AiRecommendationItem> items;
  final double total;
  final String reason;

  AiRecommendation({
    required this.title,
    required this.items,
    required this.total,
    required this.reason,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return AiRecommendation(
      title: json['title'] ?? 'AI Recommended Meal Plan',
      items: rawItems
          .map((item) => AiRecommendationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
    );
  }
}
