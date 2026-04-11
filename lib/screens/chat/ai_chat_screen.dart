import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/services/openrouter_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _purple = Color(0xFF6B4B9A);
const _rose = Color(0xFFE8748A);
const _ink = Color(0xFF1A1A3E);
const _mauve = Color(0xFF5C5470);

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  final OpenRouterService _aiService = OpenRouterService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _typingAnimController;

  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  // ── Quick-prompt chips shown before first message ─────────
  static const _quickPrompts = [
    '🤰 Is my BP normal in week 28?',
    '🥦 What should I eat this trimester?',
    '📞 When should I call my doctor?',
    '📄 Explain my blood test results',
    '💤 Is my fatigue normal?',
    '🐣 How big is my baby now?',
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  // ── Send a message ────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': trimmed});
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.chat(conversationHistory: _messages);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'I\'m having a little trouble connecting right now. Please try again in a moment. 🌸',
        });
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Quick prompts (visible only before any chat)
          if (_messages.isEmpty) _buildQuickPrompts(),

          // Welcome banner (visible before any chat)
          if (_messages.isEmpty) _buildWelcomeBanner(),

          // Chat list
          Expanded(child: _buildMessageList()),

          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _purple,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MammaAI',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18, color: Colors.white),
              ),
              Text(
                'Your Pregnancy Companion',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            tooltip: 'Clear conversation',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => setState(() => _messages.clear()),
          ),
      ],
    );
  }

  // ── Welcome Banner ────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_purple.withOpacity(0.08), _rose.withOpacity(0.07)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _purple.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const Text('🌸', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi! I\'m MammaAI 💜',
                    style: GoogleFonts.dmSerifDisplay(
                        fontSize: 16, color: _ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ask me anything about your pregnancy — symptoms, nutrition, what to expect, and more.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: _mauve, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Prompt Chips ────────────────────────────────────
  Widget _buildQuickPrompts() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                _quickPrompts[i],
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: _purple),
              ),
              onPressed: () => _sendMessage(_quickPrompts[i]),
              backgroundColor: _purple.withOpacity(0.08),
              side: BorderSide(color: _purple.withOpacity(0.25)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          );
        },
      ),
    );
  }

  // ── Message List ──────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _MessageBubble(
          content: msg['content'] ?? '',
          isUser: isUser,
        );
      },
    );
  }

  // ── Typing Indicator ──────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_purple, _rose]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingAnimController,
                  builder: (_, __) {
                    final double delay = i * 0.3;
                    final double val = ((_typingAnimController.value + delay) %
                                1.0)
                            .clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _purple.withOpacity(0.3 + val * 0.7),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          // Expand button (future: voice input placeholder)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.add_rounded, color: _purple, size: 22),
          ),
          const SizedBox(width: 8),

          // Text Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _purple.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: _ink),
                decoration: InputDecoration(
                  hintText: 'Ask MammaAI anything…',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      color: _purple.withOpacity(0.45), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [_purple, _rose]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x556B4B9A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  const _MessageBubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_purple, _rose]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          // Bubble
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [_purple, _rose],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white.withOpacity(0.9),
                border: isUser ? null : Border.all(color: _purple.withOpacity(0.15)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? _purple : Colors.black)
                        .withOpacity(isUser ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isUser ? Colors.white : _ink,
                    height: 1.5,
                  ),
                  strong: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isUser ? Colors.white : _ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar dot
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _rose.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: _rose, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
