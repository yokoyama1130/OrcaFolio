import 'package:flutter/foundation.dart';
export 'models/profile_user.dart';
export 'models/portfolio_item.dart';
export 'models/profile_response.dart';


/// -------- ProfileUser --------
class ProfileUser {
  final int id;
  final String name;
  final String bio;
  final String? iconUrl;
  final Map<String, dynamic> snsLinks;

  const ProfileUser({
    required this.id,
    required this.name,
    required this.bio,
    required this.iconUrl,
    required this.snsLinks,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> sns = {};
    final rawSns = json['sns_links'];
    if (rawSns is Map) {
      sns = Map<String, dynamic>.from(rawSns);
    }
    return ProfileUser(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      bio: (json['bio'] ?? '') as String,
      iconUrl: json['icon_url'] as String?,
      snsLinks: sns,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bio': bio,
        'icon_url': iconUrl,
        'sns_links': snsLinks,
      };

  ProfileUser copyWith({
    int? id,
    String? name,
    String? bio,
    String? iconUrl,
    Map<String, dynamic>? snsLinks,
  }) {
    return ProfileUser(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      iconUrl: iconUrl ?? this.iconUrl,
      snsLinks: snsLinks ?? this.snsLinks,
    );
  }

  @override
  String toString() => 'ProfileUser(id: $id, name: $name, iconUrl: $iconUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileUser &&
        other.id == id &&
        other.name == name &&
        other.bio == bio &&
        other.iconUrl == iconUrl &&
        mapEquals(other.snsLinks, snsLinks);
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ bio.hashCode ^ iconUrl.hashCode ^ snsLinks.hashCode;
}

/// -------- PortfolioItem --------
class PortfolioItem {
  final int id;
  final String title;
  final String? imageUrl;
  final int likes;
  final String? created;

  const PortfolioItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.likes,
    required this.created,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      likes: (json['likes'] is int)
          ? json['likes'] as int
          : (json['likes'] as num?)?.toInt() ?? 0,
      created: json['created'] as String?,
    );
    }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image_url': imageUrl,
        'likes': likes,
        'created': created,
      };

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
      id.hashCode ^ title.hashCode ^ imageUrl.hashCode ^ likes.hashCode ^ created.hashCode;
}

/// -------- ProfileResponse --------
class ProfileResponse {
  final ProfileUser user;
  final int followers;
  final int followings;
  final bool isFollowing;
  final List<PortfolioItem> portfolios;

  const ProfileResponse({
    required this.user,
    required this.followers,
    required this.followings,
    required this.isFollowing,
    required this.portfolios,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map?) ?? const {};
    final list = (json['portfolios'] as List? ?? [])
        .whereType<Map>()
        .map((e) => PortfolioItem.fromJson(e.cast<String, dynamic>()))
        .toList();

    return ProfileResponse(
      user: ProfileUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      followers: (stats['followers'] is int)
          ? stats['followers'] as int
          : (stats['followers'] as num?)?.toInt() ?? 0,
      followings: (stats['followings'] is int)
          ? stats['followings'] as int
          : (stats['followings'] as num?)?.toInt() ?? 0,
      isFollowing: (stats['is_following'] ?? false) as bool,
      portfolios: list,
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'stats': {
          'followers': followers,
          'followings': followings,
          'is_following': isFollowing,
        },
        'portfolios': portfolios.map((e) => e.toJson()).toList(),
      };

  ProfileResponse copyWith({
    ProfileUser? user,
    int? followers,
    int? followings,
    bool? isFollowing,
    List<PortfolioItem>? portfolios,
  }) {
    return ProfileResponse(
      user: user ?? this.user,
      followers: followers ?? this.followers,
      followings: followings ?? this.followings,
      isFollowing: isFollowing ?? this.isFollowing,
      portfolios: portfolios ?? this.portfolios,
    );
  }

  @override
  String toString() =>
      'ProfileResponse(user: ${user.name}, followers: $followers, portfolios: ${portfolios.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileResponse &&
        other.user == user &&
        other.followers == followers &&
        other.followings == followings &&
        other.isFollowing == isFollowing &&
        _listEquals(other.portfolios, portfolios);
  }

  @override
  int get hashCode =>
      user.hashCode ^ followers.hashCode ^ followings.hashCode ^ isFollowing.hashCode ^ portfolios.hashCode;

  static bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
