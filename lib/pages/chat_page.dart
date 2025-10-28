import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ---- Chat用モデル ----
class ChatMessage {
  final int id;
  final bool fromMe;
  final String text;
  final DateTime created;

  ChatMessage({
    required this.id,
    required this.fromMe,
    required this.text,
    required this.created,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      id: j['id'] as int,
      fromMe: j['fromMe'] as bool,
      text: j['text'] as String,
      created: DateTime.parse(j['created'] as String),
    );
  }
}

/// ---- APIクライアント ----
/// JWT が空なら ?as_uid を必ず付与して叩く（開発用フォールバック）
class ChatApiClient {
  ChatApiClient({
    required this.baseUrl,
    this.token = '',
    this.bypassUserId = 38, // ← 会話8の参加者に合わせて既定38
  });

  final String baseUrl;     // 例: http://127.0.0.1:8765
  final String token;       // 本番は JWT を入れる
  final int bypassUserId;   // 擬似ログインユーザー（会話参加者の Users.id）

  Map<String, String> _headers() {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Uri _uri(String path, Map<String, String> params) {
    final qp = Map<String, String>.from(params);
    // JWTが空なら ?as_uid を強制付与
    if (token.isEmpty && bypassUserId > 0) qp['as_uid'] = '$bypassUserId';
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: qp);
    if (kDebugMode) {
      debugPrint('[ChatApiClient] -> $uri');
      debugPrint('[ChatApiClient] Authorization: ${_headers()['Authorization'] ?? '(none)'}');
    }
    return uri;
  }

  Future<List<ChatMessage>> fetchMessages({
    required int conversationId,
    int limit = 30,
    int? beforeId,
  }) async {
    final params = <String, String>{
      'conversation_id': '$conversationId',
      'limit': '$limit',
    };
    if (beforeId != null) params['before_id'] = '$beforeId';

    final res = await http.get(_uri('/api/messages.json', params), headers: _headers());
    if (kDebugMode) {
      debugPrint('[ChatApiClient] <- ${res.statusCode} ${res.body}');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to load messages: ${res.statusCode} ${res.body}');
    }
    if (res.body.trim().isEmpty) return <ChatMessage>[];

    final map = json.decode(res.body) as Map<String, dynamic>;
    final list = (map['messages'] as List).cast<Map<String, dynamic>>();
    // サニタイズ：空文は弾く
    return list.map(ChatMessage.fromJson).where((m) => m.text.trim().isNotEmpty).toList();
  }

  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String text,
  }) async {
    final res = await http.post(
      _uri('/api/messages/send.json', {}),
      headers: _headers(),
      body: json.encode({'conversation_id': conversationId, 'text': text}),
    );
    if (kDebugMode) {
      debugPrint('[ChatApiClient][send] <- ${res.statusCode} ${res.body}');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to send message: ${res.statusCode} ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return ChatMessage.fromJson(map['message'] as Map<String, dynamic>);
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    required this.username,
    required this.avatarUrl,
    this.apiBaseUrl = 'http://127.0.0.1:8765', // iOSシミュレータなら 127.0.0.1
    this.jwtToken = '',                         // 空→ as_uid で疑似ログイン
    this.bypassUserId = 38,                     // 既定38（必要なら呼び出し側で43等に）
  });

  final int conversationId;
  final String username;
  final String avatarUrl;
  final String apiBaseUrl;
  final String jwtToken;
  final int bypassUserId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late final ChatApiClient _api;

  final List<ChatMessage> _messages = [];
  bool _loadingInit = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int? _nextBeforeId;

  // 初回二重フェッチ防止
  bool _didFetchOnce = false;

  @override
  void initState() {
    super.initState();
    _api = ChatApiClient(
      baseUrl: widget.apiBaseUrl,
      token: widget.jwtToken,
      bypassUserId: widget.bypassUserId,
    );
    _safeFetchInitial();

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels <= 80 &&
          !_loadingMore &&
          _hasMore &&
          !_loadingInit) {
        _loadMore();
      }
    });
  }

  Future<void> _safeFetchInitial() async {
    if (_didFetchOnce) return;
    _didFetchOnce = true;
    await _fetchInitial();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInitial() async {
    try {
      final items = await _api.fetchMessages(conversationId: widget.conversationId);
      final filtered = items.where((m) => m.text.trim().isNotEmpty).toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(filtered);
        _loadingInit = false;
        _nextBeforeId = _messages.isNotEmpty ? _messages.first.id : null;
        _hasMore = filtered.length >= 30;
      });
      await Future.delayed(const Duration(milliseconds: 30));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    } catch (e) {
      setState(() => _loadingInit = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('読み込みエラー: $e')),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_nextBeforeId == null) return;
    setState(() => _loadingMore = true);
    try {
      final older = await _api.fetchMessages(
        conversationId: widget.conversationId,
        beforeId: _nextBeforeId,
      );
      final olderFiltered = older.where((m) => m.text.trim().isNotEmpty).toList();

      final beforeExtent = _scrollCtrl.position.maxScrollExtent;
      setState(() {
        _messages.insertAll(0, olderFiltered);
        _nextBeforeId = _messages.isNotEmpty ? _messages.first.id : null;
        _hasMore = olderFiltered.length >= 30;
      });
      await Future.delayed(const Duration(milliseconds: 16));
      final afterExtent = _scrollCtrl.position.maxScrollExtent;
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.pixels + (afterExtent - beforeExtent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('さらに読み込み失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    // 楽観追加（仮IDは負の値）
    final temp = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      fromMe: true,
      text: text,
      created: DateTime.now(),
    );
    setState(() => _messages.add(temp));
    _textCtrl.clear();

    try {
      final saved = await _api.sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );
      final i = _messages.indexWhere((m) => m.id == temp.id);
      if (!mounted) return;
      if (i >= 0) setState(() => _messages[i] = saved);
      await Future.delayed(const Duration(milliseconds: 16));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.id == temp.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信失敗: $e')),
      );
    }
  }

  String _formatTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: (widget.avatarUrl.isNotEmpty)
                  ? NetworkImage(widget.avatarUrl)
                  : null,
              child: widget.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.username,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'ID: ${widget.conversationId}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingInit
                ? const Center(child: CircularProgressIndicator())
                : (_messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'まだメッセージがありません。\n最初のメッセージを送ってみよう！',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchInitial,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_loadingMore && index == 0) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            final msg = _messages[_loadingMore ? index - 1 : index];
                            final fromMe = msg.fromMe;
                            final time = _formatTime(msg.created);

                            return Align(
                              alignment:
                                  fromMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: fromMe
                                      ? Colors.blueAccent.withValues(alpha: 0.85)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: fromMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.text,
                                      style: TextStyle(
                                        color: fromMe ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: fromMe ? Colors.white70 : Colors.black54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'メッセージを入力…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleSend,
                    icon: const Icon(Icons.send),
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
