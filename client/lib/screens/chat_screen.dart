import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class ChatScreen extends StatefulWidget {
  final int? conversationId;

  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late ScrollController _scrollController;
  int? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentConversationId = widget.conversationId;

    if (widget.conversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final conversationProvider = context.read<ConversationProvider>();
        await conversationProvider.loadConversation(widget.conversationId!);
        final conversation = conversationProvider.currentConversation;

        if (conversation != null) {
          final chatProvider = context.read<ChatProvider>();
          chatProvider.loadMessages(
            conversation.messages,
            conversationId: conversation.id,
          );
          _currentConversationId = conversation.id;
          _scrollToBottom();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().clearMessages();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _scrollToBottom();

    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(
      message: message,
      conversationId: _currentConversationId,
    );

    if (_currentConversationId == null) {
      final conversationProvider = context.read<ConversationProvider>();
      if (conversationProvider.currentConversation != null) {
        _currentConversationId = conversationProvider.currentConversation!.id;
      }
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFFECECEC), size: 22),
          onPressed: () => Navigator.of(context).pushNamed('/conversations'),
        ),
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            return const Text(
              'ChatGPT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFECECEC), size: 22),
            onPressed: () {
              context.read<ChatProvider>().clearMessages();
              setState(() => _currentConversationId = null);
            },
            tooltip: 'New chat',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFECECEC), size: 22),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.07)),
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final messages = chatProvider.messages;

                if (messages.isEmpty) {
                  return _EmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageRow(message: message);
                  },
                );
              },
            ),
          ),

          // Typing indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (!chatProvider.isLoading) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                alignment: Alignment.centerLeft,
                child: const _TypingIndicator(),
              );
            },
          ),

          // Input area
          _InputBar(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Empty state
// ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF10A37F).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF10A37F), size: 30),
          ),
          const SizedBox(height: 20),
          const Text(
            'How can I help you today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation below',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Message row (user right, assistant left)
// ──────────────────────────────────────────────
class _MessageRow extends StatelessWidget {
  final dynamic message;
  const _MessageRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser as bool;

    if (isUser) {
      // User bubble — right-aligned pill
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F2F2F),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  message.content as String,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant message — full-width, no bubble, with avatar
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small GPT-style avatar
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10A37F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
          ),
          Expanded(
            child: Text(
              message.content as String,
              style: const TextStyle(
                color: Color(0xFFECECEC),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Typing / loading indicator
// ──────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF10A37F),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              children: List.generate(3, (i) {
                final delay = i * 0.33;
                final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Input bar
// ──────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: const Color(0xFF10A37F),
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Message ChatGPT',
                  hintStyle: TextStyle(color: Color(0xFF565869), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hasText ? const Color(0xFF10A37F) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    color: _hasText ? Colors.white : const Color(0xFF565869),
                    size: 20,
                  ),
                  onPressed: _hasText ? widget.onSend : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}