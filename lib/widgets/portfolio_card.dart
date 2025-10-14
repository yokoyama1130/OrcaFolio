import 'package:flutter/material.dart';

class PortfolioCard extends StatefulWidget {
  final String username;
  final String title;
  final String imageUrl;
  final int likes;
  final bool initiallyLiked;
  final bool initiallyFollowed;

  const PortfolioCard({
    super.key,
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

    // await http.post(Uri.parse('https://example.com/api/likes/toggle'), body: {...})
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
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/detail', arguments: {
            'username': widget.username,
            'title': widget.title,
            'imageUrl': widget.imageUrl,
            'likes': _likeCount,
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(widget.imageUrl,
                  fit: BoxFit.cover, width: double.infinity, height: 200),
            ),
            // 情報欄
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 投稿者＋フォローボタン
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
                          color:
                              _isFollowed ? Colors.blueAccent : Colors.grey[600],
                          size: 18,
                        ),
                        label: Text(
                          _isFollowed ? 'フォロー中' : 'フォロー',
                          style: TextStyle(
                            color: _isFollowed
                                ? Colors.blueAccent
                                : Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // タイトル
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  // いいね行
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _isLiked
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: _isLiked ? Colors.redAccent : Colors.grey[700],
                        ),
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
