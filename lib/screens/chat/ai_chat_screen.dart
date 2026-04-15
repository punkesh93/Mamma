import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/openrouter_service.dart';
import '../../providers/auth_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _purple = Color(0xFF6B4B9A);
const _rose = Color(0xFFE8748A);
const _ink = Color(0xFF1A1A3E);
const _mauve = Color(0xFF5C5470);
const _lavender = Color(0xFF9B86BD);
const _cream = Color(0xFFFFF8F5);

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

  List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  bool _isLoadingHistory = true;

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
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('ai_chat_history');
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages = decoded.map((m) => Map<String, String>.from(m)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
      _scrollToBottom();
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_chat_history', jsonEncode(_messages));
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear History?', style: GoogleFonts.dmSerifDisplay()),
        content: const Text('This will delete all messages in this conversation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _messages.clear());
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_chat_history');
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (mounted) {
      setState(() {
        _messages.add({'role': 'user', 'content': trimmed});
        _isTyping = true;
      });
    }
    _messageController.clear();
    _scrollToBottom();
    _saveChatHistory();

    try {
      final response = await _aiService.chat(conversationHistory: _messages);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
        });
        _saveChatHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'I\'m having a little trouble connecting right now. Please try again in a moment. 🌸',
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userData;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('MammaBuddy AI', style: GoogleFonts.dmSerifDisplay(color: _ink)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (isPremium && _messages.isNotEmpty)
            IconButton(
              onPressed: _clearChatHistory,
              icon: const Icon(Icons.delete_outline, color: _mauve),
              tooltip: 'Clear Chat',
            ),
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ActionChip(
                label: Text('Upgrade', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: _rose,
                onPressed: () => context.push('/paywall'),
              ),
            ),
        ],
      ),
      body: !isPremium 
          ? _buildLockedState()
          : _isLoadingHistory 
              ? const Center(child: CircularProgressIndicator(color: _rose))
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                return _MessageBubble(
                                  content: msg['content'] ?? '',
                                  isUser: msg['role'] == 'user',
                                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
                              },
                            ),
                    ),
                    if (_isTyping) _buildTypingIndicator(),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _lavender.withOpacity(0.1), 
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _lavender.withOpacity(0.2), blurRadius: 20)],
              ),
              child: const Icon(Icons.lock, size: 64, color: _lavender),
            ),
            const SizedBox(height: 24),
            Text('Premium AI Companion', style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: _ink)),
            const SizedBox(height: 12),
            Text(
              'Unlock 24/7 access to your personalized AI maternity assistant. Get instant, expert advice on nutrition, symptoms, and more.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: _mauve, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text('Upgrade to MammaBuddy Plus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'How can I help you today?',
              style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: _ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your pregnancy journey',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _mauve),
            ),
            const SizedBox(height: 32),
            _buildQuickPromptsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPromptsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _quickPrompts.map((p) => ActionChip(
          label: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mauve)),
          backgroundColor: _cream,
          side: BorderSide(color: _rose.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onPressed: () => _sendMessage(p),
        )).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _cream, 
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _rose.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingAnimController,
                  builder: (_, __) {
                    final double val = ((_typingAnimController.value + (i * 0.3)) % 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _purple.withOpacity(0.3 + val * 0.7)),
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

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask MammaBuddy...',
                filled: true,
                fillColor: _cream,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                hintStyle: GoogleFonts.plusJakartaSans(color: _mauve.withOpacity(0.5)),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(color: _rose, shape: BoxShape.circle),
            child: IconButton(
              onPressed: () => _sendMessage(_messageController.text),
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  const _MessageBubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) 
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
                child: const Center(child: Text('🍼', style: TextStyle(fontSize: 14))),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? const LinearGradient(colors: [_purple, _rose]) : null,
                color: isUser ? null : _cream,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                border: isUser ? null : Border.all(color: _rose.withOpacity(0.1)),
              ),
              child: MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.plusJakartaSans(fontSize: 14, color: isUser ? Colors.white : _ink, height: 1.5),
                  strong: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isUser ? Colors.white : _ink),
                  listBullet: TextStyle(color: isUser ? Colors.white : _rose),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
