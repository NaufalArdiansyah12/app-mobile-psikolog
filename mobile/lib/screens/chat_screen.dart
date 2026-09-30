import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/breathing_bubble_widget.dart';
import '../widgets/crisis_modal_overlay.dart';
import '../widgets/grounding_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  List<String> _suggestedChips = [
    "Bantu aku tenang",
    "Pikiranku berisik",
    "Latihan napas",
    "Grounding 5-4-3-2-1",
  ];
  bool _isStreaming = false;
  String _userUuid = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final uuid = await _storage.getOrCreateUserUuid();
    final name = await _storage.getNickname();
    setState(() {
      _userUuid = uuid;
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: "Halo $name. Aku MindPal, pendamping emosionalmu. Apa yang sedang membebani pikiranmu saat ini?",
        ),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) async {
    final query = (text ?? _textController.text).trim();
    if (query.isEmpty || _isStreaming) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: query));
      _messages.add(ChatMessage(role: 'assistant', content: ''));
      _isStreaming = true;
    });
    _scrollToBottom();

    final stream = _apiService.streamChatMessage(
      userUuid: _userUuid,
      message: query,
      history: _messages.sublist(0, _messages.length - 1),
    );

    try {
      await for (final chunk in stream) {
        if (chunk.isCrisis && mounted) {
          CrisisModalOverlay.show(context);
        }

        setState(() {
          final last = _messages.last;
          _messages[_messages.length - 1] = ChatMessage(
            role: 'assistant',
            content: last.content + chunk.delta,
            isCrisis: chunk.isCrisis,
          );
          if (chunk.suggestedChips.isNotEmpty) {
            _suggestedChips = chunk.suggestedChips;
          }
        });
        _scrollToBottom();

        if (chunk.triggerExercise == 'breathing') {
          _showBreathingModal();
        }
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isStreaming = false);
    }
  }

  void _showBreathingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: BreathingBubbleWidget(),
      ),
    );
  }

  void _showGroundingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: GroundingExerciseWidget(),
      ),
    );
  }

  void _resetConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mulai Sesi Baru?"),
        content: const Text("Percakapan saat ini akan dibersihkan untuk topik baru."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    role: 'assistant',
                    content: "Sesi baru dimulai. Apa yang ingin kamu bicarakan sekarang?",
                  ),
                );
              });
            },
            child: const Text("Mulai Baru"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MindPal AI", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Sesi Baru",
            onPressed: _resetConversation,
          ),
          IconButton(
            icon: const Icon(Icons.psychology_outlined, color: Colors.blueAccent),
            tooltip: "Grounding 5-4-3-2-1",
            onPressed: _showGroundingModal,
          ),
          IconButton(
            icon: const Icon(Icons.air, color: Colors.teal),
            tooltip: "Latihan Napas",
            onPressed: _showBreathingModal,
          ),
          IconButton(
            icon: const Icon(Icons.sos_rounded, color: Colors.redAccent),
            tooltip: "Bantuan Darurat SOS",
            onPressed: () => CrisisModalOverlay.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.teal.shade600
                          : (msg.isCrisis ? Colors.red.shade50 : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: msg.isCrisis
                          ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Text(
                      msg.content.isEmpty && _isStreaming && !isUser
                          ? "Mengetik..."
                          : msg.content,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: isUser
                            ? Colors.white
                            : (msg.isCrisis ? Colors.red.shade900 : Colors.black87),
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Chips
          if (_suggestedChips.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: _suggestedChips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(chip, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        if (chip.toLowerCase().contains("napas")) {
                          _showBreathingModal();
                        } else if (chip.toLowerCase().contains("grounding")) {
                          _showGroundingModal();
                        } else if (chip.toLowerCase().contains("119")) {
                          CrisisModalOverlay.show(context);
                        } else {
                          _sendMessage(chip);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Ceritakan apa yang kamu rasakan...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isStreaming ? null : () => _sendMessage(),
                    icon: Icon(
                      Icons.send_rounded,
                      color: _isStreaming ? Colors.grey : Colors.teal.shade600,
                    ),
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
