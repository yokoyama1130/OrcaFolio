import 'package:flutter/material.dart';

class PortfolioCard extends StatefulWidget {
  final int portfolioId;
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
  late bool _isLiked;
  late bool _isFollowed;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
    _isFollowed = widget.initiallyFollowed;
    _likeCount = widget.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _toggleFollow() {
    setState(() {
      _isFollowed = !_isFollowed;
    });
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
            'id': widget.portfolioId,        // ← 修正
            'apiBaseUrl': widget.apiBaseUrl, // ← 修正（ハードコードしない）
            'username': widget.username,
            'title': widget.title,
            'imageUrl': widget.imageUrl,
            'likes': _likeCount,
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像（16:9）
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _NetworkThumb(url: widget.imageUrl),
            ),

            // 情報欄
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

                  // タイトル
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  // いいね
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                          color: _isLiked ? Colors.redAccent : Colors.grey[800],
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
    debugPrint('[PortfolioCard] loading image: $url');

    final placeholder = Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 40, color: Colors.black26),
    );

    final error = Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.broken_image_outlined, size: 36, color: Colors.black38),
          SizedBox(height: 6),
          Text('画像を読み込めませんでした', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        }
        return placeholder;
      },
      errorBuilder: (context, _, __) => error,
    );
  }
}
