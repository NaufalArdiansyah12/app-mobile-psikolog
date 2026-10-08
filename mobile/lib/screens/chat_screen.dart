import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/breathing_bubble_widget.dart';
import '../widgets/crisis_modal_overlay.dart';
import '../widgets/grounding_widget.dart';
import '../widgets/typing_indicator.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final ChatSession? initialSession;

  const ChatScreen({
    super.key,
    this.initialSession,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  List<String> _suggestedChips = [
    "Bantu aku tenang",
    "Pikiranku berisik",
    "Latihan napas",
    "Grounding 5-4-3-2-1",
  ];
  bool _isStreaming = false;
  bool _hasUnsavedMessages = false;
  String _userUuid = '';
  String _userName = 'Teman';
  String _userAvatar = 'asset:assets/gambar_home.jpeg';
  String _currentSessionId = const Uuid().v4();

  bool get hasUnsavedMessages =>
      _hasUnsavedMessages && _messages.any((m) => m.role == 'user');

  @override
  void initState() {
    super.initState();
    if (widget.initialSession != null) {
      _currentSessionId = widget.initialSession!.id;
      _messages.addAll(widget.initialSession!.messages);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _loadUser();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadUser() async {
    final uuid = await _storage.getOrCreateUserUuid();
    final name = await _storage.getNickname();
    final avatar = await _storage.getUserAvatar(userUuid: uuid);
    if (mounted) {
      setState(() {
        _userUuid = uuid;
        _userName = (name != null && name.isNotEmpty) ? name : 'Teman';
        _userAvatar = avatar ?? 'asset:assets/gambar_home.jpeg';
        if (widget.initialSession == null && _messages.isEmpty) {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: "Halo $_userName. Aku Hevenly, pendamping emosionalmu. Apa yang sedang membebani pikiranmu saat ini?",
            ),
          );
        }
      });
    }
  }

  Widget _buildUserAvatar() {
    if (_userAvatar.startsWith('asset:')) {
      final path = _userAvatar.replaceFirst('asset:', '');
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFFEF3C7),
              child: const Center(child: Text("🌸", style: TextStyle(fontSize: 14))),
            ),
          ),
        ),
      );
    } else if (_userAvatar.startsWith('file:')) {
      final path = _userAvatar.replaceFirst('file:', '');
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFFEF3C7),
              child: const Center(child: Text("🌸", style: TextStyle(fontSize: 14))),
            ),
          ),
        ),
      );
    } else if (_userAvatar.startsWith('emoji:')) {
      final emoji = _userAvatar.replaceFirst('emoji:', '');
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFEF3C7),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFEF3C7),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Center(child: Text("🌸", style: TextStyle(fontSize: 16))),
    );
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
      _hasUnsavedMessages = true;
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

  // Simpan sesi ke riwayat secara instan & minta analisis AI di background (non-blocking)
  Future<void> _saveCurrentSession() async {
    final userMessages = _messages.where((m) => m.role == 'user').toList();
    if (userMessages.isEmpty) return;

    final validMessages = List<ChatMessage>.from(_messages.where((m) => m.content.isNotEmpty));
    final sessionId = _currentSessionId;
    final sessionUuid = _userUuid;

    // 1. Simpan langsung ke penyimpanan lokal agar instan & data tidak hilang
    final session = ChatSession(
      id: sessionId,
      messages: validMessages,
      analysis: null,
    );
    await _storage.saveChatSession(session);
    if (mounted) {
      setState(() => _hasUnsavedMessages = false);
    }

    // 2. Analisis AI dijalankan di background lalu memperbarui sesi di storage
    _apiService.analyzeChatSession(
      userUuid: sessionUuid,
      messages: validMessages,
    ).then((analysis) async {
      if (analysis != null) {
        final updatedSession = ChatSession(
          id: sessionId,
          messages: validMessages,
          analysis: analysis,
        );
        await _storage.saveChatSession(updatedSession);
      }
    }).catchError((_) {});
  }

  // Dialog konfirmasi saat berpindah halaman jika chat belum disimpan
  Future<bool> confirmExitIfUnsaved() async {
    if (!hasUnsavedMessages) return true;

    // Tutup keyboard dan cabut fokus input agar keyboard tidak muncul
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bookmark_border_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Simpan Percakapan?",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          "Kamu memiliki percakapan yang belum disimpan. Apakah kamu ingin menyimpannya ke Jurnal sebelum berpindah halaman?",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () {
              _focusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx, 'cancel');
            },
            child: Text(
              "Batal",
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _focusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx, 'discard');
            },
            child: Text(
              "Tidak",
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              _focusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx, 'save');
            },
            child: Text(
              "Simpan",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    // Pastikan fokus tetap bersih setelah dialog ditutup
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    if (result == 'save') {
      await _saveCurrentSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Percakapan berhasil disimpan ke Jurnal.",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
        setState(() {
          _currentSessionId = const Uuid().v4();
          _messages.clear();
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: "Halo $_userName. Aku Hevenly, pendamping emosionalmu. Apa yang sedang membebani pikiranmu saat ini?",
            ),
          );
          _hasUnsavedMessages = false;
        });
      }
      return true;
    } else if (result == 'discard') {
      if (mounted) {
        setState(() {
          _currentSessionId = const Uuid().v4();
          _messages.clear();
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: "Halo $_userName. Aku Hevenly, pendamping emosionalmu. Apa yang sedang membebani pikiranmu saat ini?",
            ),
          );
          _hasUnsavedMessages = false;
        });
      }
      return true;
    }

    // 'cancel' atau dismiss: tetap di halaman chat
    return false;
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
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final hasUserMsg = _messages.any((m) => m.role == 'user');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Selesaikan Sesi?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          hasUserMsg
              ? "Sesi ini akan dianalisis oleh AI dan otomatis disimpan ke Jurnal Catatan."
              : "Mulai percakapan baru dari awal.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _focusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              _focusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
              if (hasUserMsg) {
                await _saveCurrentSession();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Sesi berhasil disimpan ke Jurnal.",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              if (mounted) {
                setState(() {
                  _currentSessionId = const Uuid().v4();
                  _messages.clear();
                  _messages.add(
                    ChatMessage(
                      role: 'assistant',
                      content: "Sesi baru dimulai. Apa yang ingin kamu bicarakan sekarang?",
                    ),
                  );
                  _hasUnsavedMessages = false;
                });
              }
            },
            child: Text("Selesai & Simpan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF006D77);
    final bool canPopRoute = Navigator.canPop(context);

    final Widget scaffold = Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP HEADER (Hijau Aqua / Deep Teal)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
              child: Row(
                children: [
                  if (canPopRoute) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.only(right: 6),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      tooltip: "Kembali",
                      onPressed: () async {
                        final shouldPop = await confirmExitIfUnsaved();
                        if (shouldPop && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                  Stack(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_awesome_rounded, color: primaryTeal, size: 20),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Hevenly AI",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.initialSession != null
                              ? "Lanjutan Sesi Jurnal • Aktif 24/7"
                              : "Aktif 24/7 • Pendamping Pribadi",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Actions Buttons
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white, size: 20),
                    tooltip: "Simpan ke Jurnal",
                    onPressed: () async {
                      final hasUserMsg = _messages.any((m) => m.role == 'user');
                      if (!hasUserMsg) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Belum ada obrolan untuk disimpan.",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Menganalisis emosi dan menyimpan ke Jurnal...",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF0F172A),
                        ),
                      );
                      await _saveCurrentSession();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Sesi berhasil diarsipkan ke Tab Jurnal!",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF0D9488),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    tooltip: "Sesi Baru",
                    onPressed: _resetConversation,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.psychology_outlined, color: Colors.white, size: 20),
                    tooltip: "Grounding 5-4-3-2-1",
                    onPressed: _showGroundingModal,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.air_rounded, color: Colors.white, size: 20),
                    tooltip: "Latihan Napas",
                    onPressed: _showBreathingModal,
                  ),
                ],
              ),
            ),

            // 2. BOTTOM HALF CURVED CARD (Card Putih Melengkung)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == 'user';

                if (isUser) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(4),
                                bottomLeft: Radius.circular(22),
                                bottomRight: Radius.circular(22),
                              ),
                              border: Border.all(color: const Color(0xFF99F6E4)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg.content,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildUserAvatar(),
                      ],
                    ),
                  );
                }

                // AI Message Bubble
                final isThinking = msg.content.isEmpty && _isStreaming;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0D9488),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: msg.isCrisis ? const Color(0xFFFFF1F2) : Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(22),
                              bottomLeft: Radius.circular(22),
                              bottomRight: Radius.circular(22),
                            ),
                            border: Border.all(
                              color: msg.isCrisis ? const Color(0xFFFECDD3) : const Color(0xFFF1F5F9),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isThinking
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: TypingIndicator(
                                    dotColor: Color(0xFF0D9488),
                                    dotSize: 7.5,
                                  ),
                                )
                              : Text(
                                  msg.content,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: msg.isCrisis ? const Color(0xFFBE185D) : const Color(0xFF334155),
                                    height: 1.45,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Suggested Chips (Liquid Glass effect)
          if (_suggestedChips.isNotEmpty)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedChips.length,
                itemBuilder: (context, idx) {
                  final chip = _suggestedChips[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
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
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  chip,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Input Dock
          Builder(
            builder: (context) {
              final mediaQuery = MediaQuery.of(context);
              final bool isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
              final double systemBottom = mediaQuery.padding.bottom;
              // Ruang pas di atas floating bottom navigation bar (tidak terlalu jauh & tidak mepet)
              final double bottomInset = isKeyboardOpen
                  ? 8.0
                  : (systemBottom > 8.0 ? (systemBottom + 10.0) : 14.0);

              return Container(
                padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 3,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText: "Ceritakan apa yang kamu rasakan...",
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _isStreaming ? null : () => _sendMessage(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isStreaming ? const Color(0xFF94A3B8) : const Color(0xFF0D9488),
                            boxShadow: [
                              if (!_isStreaming)
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
              ),
            ),
          ],
        ),
      ),
    );

    if (canPopRoute) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await confirmExitIfUnsaved();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        },
        child: scaffold,
      );
    }

    return scaffold;
  }
}
