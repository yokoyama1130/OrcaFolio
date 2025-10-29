// lib/widgets/portfolio_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PortfolioCard extends StatefulWidget {
  final int portfolioId;
  final int authorUserId;          // ★ 追加: 投稿者ユーザーID（フォロー対象）
  final String apiBaseUrl;
  final String username;
  final String title;
  final String imageUrl;
  final int likes;
  final bool initiallyLiked;
  final bool initiallyFollowed;

  const PortfolioCard({
    super.key,
    required this.portfolioId,
    required this.authorUserId,    // ★ 追加
    required this.apiBaseUrl,
    required this.username,
    required this.title,
    required this.imageUrl,
    required this.likes,
    this.initiallyLiked = false,
    this.initiallyFollowed = false,
  });

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  static const _storage = FlutterSecureStorage();

  late bool _isLiked;
  late bool _isFollowed;
  late int _likeCount;
  late final Uri _normalizedBase;

  bool _liking = false;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
    _isFollowed = widget.initiallyFollowed;
    _likeCount = widget.likes;

    final baseUri = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    _normalizedBase =
        baseUri.host == 'localhost' ? baseUri.replace(host: '127.0.0.1') : baseUri;
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    _liking = true;

    final prevLiked = _isLiked;
    final prevCount = _likeCount;

    // 楽観更新
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null || token.isEmpty) throw Exception('ログインが必要です（トークンなし）');

      final uri = _normalizedBase.replace(path: '/api/likes/toggle.json');
      final res = await http
          .post(uri, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          }, body: {
            'portfolio_id': '${widget.portfolioId}',
          })
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } on TimeoutException {
      _rollback(prevLiked, prevCount, null, null, 'タイムアウトしました');
    } catch (e) {
      _rollback(prevLiked, prevCount, null, null, 'いいねに失敗しました: $e');
    } finally {
      _liking = false;
    }
  }

  Future<void> _toggleFollow() async {
    if (_following) return;
    _following = true;

    final prevFollow = _isFollowed;

    // 楽観更新
    setState(() => _isFollowed = !_isFollowed);

    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null || token.isEmpty) throw Exception('ログインが必要です（トークンなし）');

      final uri = _normalizedBase.replace(path: '/api/follows/toggle.json');
      final res = await http
          .post(uri, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          }, body: {
            'target_user_id': '${widget.authorUserId}', // ← 投稿者をフォロー
          })
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } on TimeoutException {
      _rollback(null, null, prevFollow, null, 'タイムアウトしました');
    } catch (e) {
      _rollback(null, null, prevFollow, null, 'フォローに失敗しました: $e');
    } finally {
      _following = false;
    }
  }

  void _rollback(bool? prevLiked, int? prevCount, bool? prevFollow, int? _,
      String message) {
    if (!mounted) return;
    setState(() {
      if (prevLiked != null && prevCount != null) {
        _isLiked = prevLiked;
        _likeCount = prevCount;
      }
      if (prevFollow != null) {
        _isFollowed = prevFollow;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/detail', arguments: {
            'id': widget.portfolioId,
            'apiBaseUrl': widget.apiBaseUrl,
            'username': widget.username,
            'title': widget.title,
            'imageUrl': widget.imageUrl,
            'likes': _likeCount,
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _NetworkThumb(url: widget.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 投稿者＋フォロー
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('@${widget.username}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _toggleFollow,
                        icon: Icon(
                          _isFollowed
                              ? Icons.check_circle
                              : Icons.person_add_alt_1_outlined,
                          color: _isFollowed ? Colors.blueAccent : Colors.grey[700],
                          size: 18,
                        ),
                        label: Text(
                          _isFollowed ? 'フォロー中' : 'フォロー',
                          style: TextStyle(
                            color: _isFollowed ? Colors.blueAccent : Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                          color: _isLiked ? Colors.pinkAccent : Colors.grey[800],
                        ),
                        tooltip: _isLiked ? 'いいね済み' : 'いいね',
                      ),
                      Text('$_likeCount'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkThumb extends StatelessWidget {
  const _NetworkThumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 40),
    );
    final error = Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.broken_image_outlined, size: 36),
          SizedBox(height: 6),
          Text('画像を読み込めませんでした'),
        ],
      ),
    );

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        }
        return placeholder;
      },
      errorBuilder: (_, __, ___) => error,
    );
  }
}
