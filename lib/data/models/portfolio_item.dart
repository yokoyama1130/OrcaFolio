// lib/data/models/portfolio_item.dart

/// ユーザーのポートフォリオ1件分
class PortfolioItem {
  final int id;
  final String title;
  final String? imageUrl;
  final int likes;
  /// APIは文字列で返す想定（必要なら呼び出し側で DateTime に変換）
  final String? created;

  const PortfolioItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.likes,
    required this.created,
  });

  /// 動的値を安全に int 化
  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'] as String?;
    final normalizedImage =
        (rawImage != null && rawImage.trim().isNotEmpty) ? rawImage : null;

    return PortfolioItem(
      id: _asInt(json['id']),
      title: (json['title'] ?? '') as String,
      imageUrl: normalizedImage,
      likes: _asInt(json['likes']),
      created: json['created'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'likes': likes,
      'created': created,
    };
  }

  PortfolioItem copyWith({
    int? id,
    String? title,
    String? imageUrl,
    int? likes,
    String? created,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      created: created ?? this.created,
    );
  }

  @override
  String toString() => 'PortfolioItem(id: $id, title: $title)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioItem &&
        other.id == id &&
        other.title == title &&
        other.imageUrl == imageUrl &&
        other.likes == likes &&
        other.created == created;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      (imageUrl?.hashCode ?? 0) ^
      likes.hashCode ^
      (created?.hashCode ?? 0);
}
