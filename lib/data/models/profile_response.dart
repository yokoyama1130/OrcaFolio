import 'profile_user.dart';
import 'portfolio_item.dart';

/// プロフィールAPIのレスポンス全体
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
      followers: (stats['followers'] ?? 0) is int
          ? stats['followers'] as int
          : (stats['followers'] as num?)?.toInt() ?? 0,
      followings: (stats['followings'] ?? 0) is int
          ? stats['followings'] as int
          : (stats['followings'] as num?)?.toInt() ?? 0,
      isFollowing: (stats['is_following'] ?? false) as bool,
      portfolios: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'stats': {
        'followers': followers,
        'followings': followings,
        'is_following': isFollowing,
      },
      'portfolios': portfolios.map((e) => e.toJson()).toList(),
    };
  }

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
    // 依存を増やしたくないので ListEquality は使っていない
  }
}
