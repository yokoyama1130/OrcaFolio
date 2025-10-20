// lib/data/models/profile_user.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// プロフィールのユーザー情報
class ProfileUser {
  final int id;
  final String name;
  final String bio;
  final String? iconUrl;
  final Map<String, dynamic> snsLinks;
  /// 任意: APIが user.created を返してくる場合に備えた受け皿（未使用なら null のままでOK）
  final String? created;

  const ProfileUser({
    required this.id,
    required this.name,
    required this.bio,
    required this.iconUrl,
    required this.snsLinks,
    this.created,
  });

  /// JSON(Map) -> Model
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    // --- id を安全に int 化（num / String の両対応）---
    int parseId(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return n;
      }
      return 0; // フォールバック
    }

    // --- sns_links は Map でも JSON文字列でも受ける ---
    Map<String, dynamic> parseSns(dynamic raw) {
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // 文字列だがJSONでなければ空Map
        }
      }
      return <String, dynamic>{};
    }

    return ProfileUser(
      id: parseId(json['id']),
      name: (json['name'] ?? '') as String,
      bio: (json['bio'] ?? '') as String,
      iconUrl: (json['icon_url'] as String?)?.trim().isEmpty == true
          ? null
          : json['icon_url'] as String?,
      snsLinks: parseSns(json['sns_links']),
      created: json['created'] as String?, // APIが返してくる場合のみ入る
    );
  }

  /// Model -> JSON(Map)
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'bio': bio,
      'icon_url': iconUrl,
      'sns_links': snsLinks,
      if (created != null) 'created': created,
    };
  }

  ProfileUser copyWith({
    int? id,
    String? name,
    String? bio,
    String? iconUrl,
    Map<String, dynamic>? snsLinks,
    String? created,
  }) {
    return ProfileUser(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      iconUrl: iconUrl ?? this.iconUrl,
      snsLinks: snsLinks ?? this.snsLinks,
      created: created ?? this.created,
    );
  }

  @override
  String toString() =>
      'ProfileUser(id: $id, name: $name, iconUrl: $iconUrl, created: $created)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileUser &&
        other.id == id &&
        other.name == name &&
        other.bio == bio &&
        other.iconUrl == iconUrl &&
        other.created == created &&
        mapEquals(other.snsLinks, snsLinks);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      bio.hashCode ^
      (iconUrl?.hashCode ?? 0) ^
      (created?.hashCode ?? 0) ^
      snsLinks.hashCode;
}
