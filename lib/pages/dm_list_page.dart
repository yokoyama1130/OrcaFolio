import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'chat_page.dart';

class DMListPage extends StatefulWidget {
  const DMListPage({
    super.key,
    required this.apiBaseUrl, // 必須
    required this.token,      // 必須（Authorization: Bearer）
  });

  final String apiBaseUrl;
  final String token;

  @override
  State<DMListPage> createState() => _DMListPageState();
}

class _DMListPageState extends State<DMListPage> {
  bool _loading = false;
  String _error = '';
  List<Map<String, dynamic>> _items = [];

  // ===== ユーティリティ =====
  Map<String, String> get _authHeaders {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (widget.token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }
    return headers;
  }

  /// localhost→127.0.0.1、相対パス→絶対URL化、/img//icons の二重スラ潰し など
  String _absUrl(String? raw, {String fallback = ''}) {
    if (raw == null || raw.isEmpty) return fallback;
    final s = raw.trim();

    // 既に http(s)
    if (s.startsWith('http://') || s.startsWith('https://')) {
      final u = Uri.parse(s);
      final fixed = (u.host == 'localhost') ? u.replace(host: '127.0.0.1') : u;
      // /img//icons -> /img/icons
      final cleaned = fixed.replace(path: fixed.path.replaceFirst('/img//', '/img/'));
      return cleaned.toString();
    }

    // 相対
    final base = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    final b = (base.host == 'localhost') ? base.replace(host: '127.0.0.1') : base;
    var path = s.startsWith('/') ? s : '/$s';
    path = path.replaceFirst('/img//', '/img/');
    return '${b.toString()}$path';
  }

  /// APIから会話一覧を取得
  Future<void> _fetchDMList() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // 実機対策: localhost→127.0.0.1
      final base = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
      final root = (base.host == 'localhost') ? base.replace(host: '127.0.0.1') : base;

      final uri = Uri.parse('${root.toString()}/api/conversations/index.json');

      final res = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 401) {
        setState(() {
          _items = [];
          _error = 'ログインが必要です（ブラウザCookieは共有されないため、アプリ側でのJWTが必要です）';
        });
        return;
      }

      if (res.statusCode != 200) {
        throw Exception('Failed: ${res.statusCode} - ${res.body}');
      }

      final decoded = json.decode(res.body);
      final map = (decoded is Map<String, dynamic>)
          ? decoded
          : <String, dynamic>{'items': decoded};

      final rawList = (map['items'] ?? map['conversations'] ?? []) as List;

      final parsed = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        _items = parsed;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDMList();
  }

  /// last_message / last_time をいい感じに取り出す
  /// - last_message が String: そのまま本文、last_time を使う
  /// - last_message が Map: {content, created} を優先し、無ければ last_time を使う
  (String text, String time) _extractLast(Map<String, dynamic> conv) {
    final lm = conv['last_message'] ?? conv['lastMessage'];
    final lt = (conv['last_time'] ?? conv['lastTime'] ?? '').toString();

    if (lm is Map) {
      final text = (lm['content'] ?? lm['body'] ?? '').toString();
      final time = (lm['created'] ?? lt).toString();
      return (text, time);
    } else if (lm is String) {
      return (lm, lt);
    } else {
      return ('', lt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noToken = widget.token.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('メッセージ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (noToken)
            Container(
              width: double.infinity,
              color: Colors.amber.shade50,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'アプリ内のDMはログイン（JWT）が必要です。ログイン後に再度お試しください。',
                style: TextStyle(color: Colors.brown),
              ),
            ),
          if (_error.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(
                'DM一覧を取得できませんでした:\n$_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchDMList,
              child: (_items.isEmpty && _error.isEmpty)
                  ? ListView( // RefreshIndicator用に空でもスクロール領域を確保
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('メッセージはまだありません')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final conv = _items[index];

                        // 会話ID（複数キーに対応）
                        final conversationId =
                            ((conv['conversation_id'] ??
                                      conv['id'] ??
                                      conv['conversationId']) as num)
                                .toInt();

                        // 相手名
                        final partnerName = (conv['partner_name'] ??
                                conv['partner']?['name'] ??
                                '???') as String;

                        // 相手アイコンURL正規化（icons/xxx.png → /img/icons/xxx.png → 絶対URL）
                        final partnerIconRaw = (conv['partner_icon_url'] ??
                            conv['partner']?['icon_url'] ??
                            conv['partner']?['icon_path']) as String?;

                        final iconPath = (partnerIconRaw != null && partnerIconRaw.startsWith('icons/'))
                            ? '/img/$partnerIconRaw'
                            : partnerIconRaw;

                        final partnerIcon = _absUrl(iconPath);

                        // 最後のメッセージ＆時刻を抽出（MapでもStringでもOK）
                        final (lastMessageText, lastMessageTime) = _extractLast(conv);

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundImage: (partnerIcon.isNotEmpty)
                                ? NetworkImage(partnerIcon)
                                : null,
                            child: (partnerIcon.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            partnerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            lastMessageText.isEmpty
                                ? '(まだメッセージがありません)'
                                : lastMessageText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            lastMessageTime,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  conversationId: conversationId,
                                  username: partnerName,
                                  avatarUrl: partnerIcon,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('再読み込み'),
                  onPressed: _fetchDMList,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
