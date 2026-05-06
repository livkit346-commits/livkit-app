import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/chat_service.dart';
import '../../services/auth_service.dart';

import '../../services/friend_service.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String title;
  final String avatarUrl;


  const ChatPage({
    super.key,
    required this.conversationId,
    required this.title,
    required this.avatarUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _myUserId;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _typingUsers = {};

  late final ChatService _chatService;
  StreamSubscription? _subscription;

  Timer? _typingTimer;
  bool _isTyping = false;

  String? _myUsername;

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(conversationId: widget.conversationId);
    _init();
  }

  Future<void> _init() async {
    await _loadMe();
    await _loadHistory();

    _chatService.connect();
    _subscription = _chatService.events.listen(_handleSocketEvent);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _subscription?.cancel();
    _chatService.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  String _senderUsername(Map msg) {
    final sender = msg["sender"];
    if (sender is Map && sender["username"] != null) {
      return sender["username"];
    }
    if (sender is String) {
      return sender; // optimistic messages only
    }
    return "";
  }


  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ─────────────────────────────────────────────
  // Loaders
  // ─────────────────────────────────────────────

  Future<void> _loadMe() async {
    final auth = AuthService();
    _myUsername = await auth.getUsername();
    _myUserId = await auth.getUserId();
  }

  int? _senderId(Map msg) {
    final sender = msg["sender"];
    if (sender is Map && sender["id"] != null) {
      return sender["id"];
    }
    return null; // optimistic messages handled separately
  }



  Map<String, dynamic> _normalizeContent(dynamic content) {
    if (content is String) {
      return {"text": content};
    }

    if (content is Map && content["text"] is String) {
      return Map<String, dynamic>.from(content);
    }

    // Fallback: never crash UI
    return {"text": ""};
  }


  Future<void> _loadHistory() async {
    final token = await AuthService().getAccessToken();
    if (token == null) return;

    final res = await http.get(
      Uri.parse(
        "https://livkit.onrender.com/api/chat/conversations/${widget.conversationId}/messages/",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) return;

    final decoded = jsonDecode(res.body);

    final List results = decoded is List
        ? decoded
        : (decoded["results"] ?? []);

    setState(() {
      _messages.addAll(
        results.whereType<Map>().map<Map<String, dynamic>>((m) {


          final senderId = _senderId(m);

          return {
            ...Map<String, dynamic>.from(m),
            "content": _normalizeContent(m["content"]),
            "is_me": senderId != null && senderId == _myUserId,
          };




        }),
      );
    });

    _scrollToBottom();
  }




  void _handleIncomingMessage(Map msg) {
    final senderId = _senderId(msg);
    final isMe = senderId != null && senderId == _myUserId;

    final serverId = msg["id"];

    final Map<String, dynamic> normalized = {
      ...Map<String, dynamic>.from(msg),
      "content": _normalizeContent(msg["content"]),
      "is_me": isMe,
    };

    final index = _messages.indexWhere(
      (m) =>
          m["pending"] == true &&
          m["content"]?["text"] == normalized["content"]?["text"],
    );

    setState(() {
      if (index != -1) {
        _messages[index] = normalized;
      } else if (!_messages.any((m) => m["id"] == serverId)) {
        _messages.add(normalized);
      }
    });

    _scrollToBottom();
  }



  // ─────────────────────────────────────────────
  // WebSocket events
  // ─────────────────────────────────────────────

  void _handleSocketEvent(Map<String, dynamic> event) {
    switch (event["type"]) {
      case "message.new":
        _handleIncomingMessage(event["message"]);
        break;

      case "typing":
        _handleTypingEvent(event);
        break;
    }
  }

  void _handleTypingEvent(Map event) {
    final user = event["user"];
    final isTyping = event["is_typing"] == true;

    if (user == null || user == _myUsername) return;

    setState(() {
      isTyping ? _typingUsers.add(user) : _typingUsers.remove(user);
    });
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // Optimistic insert
    setState(() {
      _messages.add({
        "id": "local-${DateTime.now().millisecondsSinceEpoch}",
        "sender": {
          "id": _myUserId,
          "username": _myUsername,
        },
        "content": {"text": text},
        "is_me": true,
        "pending": true,
      });

    });

    _chatService.send({
      "type": "message.send",
      "payload": {
        "message_type": "TEXT",
        "content": text,
      },
    });

    _inputController.clear();
    _scrollToBottom();
  }

  void _handleTyping(String _) {
    if (_isTyping) return;

    _isTyping = true;
    _chatService.send({
      "type": "typing.start",
      "conversation_id": widget.conversationId,
    });

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _chatService.send({
        "type": "typing.stop",
        "conversation_id": widget.conversationId,
      });
    });
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF000000);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatar(widget.title, radius: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_typingUsers.isNotEmpty)
                  Text(
                    "typing...",
                    style: TextStyle(color: const Color(0xFFFF0050).withOpacity(0.8), fontSize: 11),
                  )
                else
                  const Text(
                    "Online",
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withOpacity(0.05), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg["is_me"] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFFF0050) : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMe ? 20 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 20),
                        ),
                        boxShadow: isMe ? [
                          BoxShadow(
                            color: const Color(0xFFFF0050).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ] : null,
                      ),
                      child: Text(
                        msg["content"]?["text"] ?? "",
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputBar(bg),
        ],
      ),
    );
  }

  Widget _buildAvatar(String username, {double radius = 18}) {
    final color = Colors.primaries[username.hashCode % Colors.primaries.length];
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.8),
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : "?",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  Widget _buildInputBar(Color bg) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                onChanged: _handleTyping,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFFFF0050), size: 28),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
