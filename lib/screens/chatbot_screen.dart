import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/chatbot_responses.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─── Quick Replies ───────────────────────────────────────────────────────────

const List<String> _quickReplies = [
  "😔 I feel stressed",
  "😰 I'm anxious",
  "😢 I feel sad",
  "😴 I'm tired",
  "😊 I'm doing okay",
  "🆘 I need help",
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  bool _isTyping = false;
  bool _showSuggestions = true;
  bool _hasText = false;

  late AnimationController _headerController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _addBotMessage(ChatbotEngine.greeting);
      });
    });
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _addBotMessage(String text) {
    final msg = ChatMessage(text: text, isUser: false);
    _messages.add(msg);
    _listKey.currentState?.insertItem(
      _messages.length - 1,
      duration: const Duration(milliseconds: 400),
    );
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    final msg = ChatMessage(text: text, isUser: true);
    _messages.add(msg);
    _listKey.currentState?.insertItem(
      _messages.length - 1,
      duration: const Duration(milliseconds: 350),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() => _showSuggestions = false);
    _addUserMessage(text);
    if (overrideText == null) _controller.clear();

    setState(() => _isTyping = true);
    _scrollToBottom();

    await Future.delayed(
      Duration(milliseconds: 900 + (text.length * 6).clamp(0, 1000)),
    );
    final response = ChatbotEngine.respond(text);

    if (!mounted) return;

    setState(() => _isTyping = false);
    _addBotMessage(response.message);

    if (response.followUp != null) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() => _isTyping = true);
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage(response.followUp!);
    }

    if (response.exercisePrompt != null) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _isTyping = true);
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage("💡 ${response.exercisePrompt!}");
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMessageList()),
          if (_isTyping) _buildTypingIndicator(),
          if (_showSuggestions && _messages.length <= 1) _buildSuggestionChips(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 16,
          left: 8,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 4),
            // Avatar
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                // Online dot
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Name & status
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Serenity",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Always here to listen",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // More button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Messages ────────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedList(
      key: _listKey,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      initialItemCount: _messages.length,
      itemBuilder: (context, index, animation) {
        final msg = _messages[index];
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(msg.isUser ? 0.3 : -0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: _MessageBubble(message: msg),
          ),
        );
      },
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF818CF8).withValues(alpha: 0.1),
                  const Color(0xFF6366F1).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              size: 40,
              color: const Color(0xFF6366F1).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Welcome to Serenity",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "A safe space to share how you feel.\nI'm here to listen.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Typing Indicator ────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFF3F4F6)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _WaveDots(),
                const SizedBox(width: 10),
                Text(
                  "Serenity is typing",
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Suggestion Chips ────────────────────────────────────────────────────

  Widget _buildSuggestionChips() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(_quickReplies[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                _quickReplies[index],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Input Bar ───────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mic button (decorative)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textInputAction: TextInputAction.send,
                cursorColor: const Color(0xFF6366F1),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
                decoration: const InputDecoration(
                  hintText: "Share how you're feeling...",
                  hintStyle: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText
                    ? const Color(0xFF111827)
                    : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _hasText ? Colors.white : const Color(0xFF9CA3AF),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Message Bubble
// ═══════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                // Bot avatar (small)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10, bottom: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  child: isUser
                      ? _buildUserBubble()
                      : _buildBotBubble(),
                ),
              ),
            ],
          ),
          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              top: 6,
              left: isUser ? 0 : 38,
              right: isUser ? 4 : 0,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Text(
        message.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.45,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildBotBubble() {
    return IntrinsicHeight(
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accent bar
          Container(
            width: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Wave Dots (Typing Indicator)
// ═══════════════════════════════════════════════════════════════════════════════

class _WaveDots extends StatefulWidget {
  const _WaveDots();

  @override
  State<_WaveDots> createState() => _WaveDotsState();
}

class _WaveDotsState extends State<_WaveDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = sin((_controller.value * 2 * pi) + (i * 0.8));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -3.5 * offset.clamp(0.0, 1.0)),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFFD1D5DB),
                      const Color(0xFF818CF8),
                      offset.clamp(0.0, 1.0),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
