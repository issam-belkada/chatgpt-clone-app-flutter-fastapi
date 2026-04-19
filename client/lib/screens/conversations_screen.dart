import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().loadConversations();
    });
  }

  Future<void> _createConversation() async {
    final conversationProvider = context.read<ConversationProvider>();
    final newConversation = await conversationProvider.createConversation(
      title: 'New Conversation',
    );
    if (newConversation != null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/chat',
        arguments: newConversation.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createConversation,
          ),
        ],
      ),
      body: Consumer<ConversationProvider>(
        builder: (context, conversationProvider, child) {
          if (conversationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (conversationProvider.error != null) {
            return Center(
              child: Text(
                conversationProvider.error!,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final conversations = conversationProvider.conversations;
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _createConversation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Start a new conversation'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                title: Text(
                  conversation.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Last updated ${conversation.updatedAt.toLocal()}',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed(
                    '/chat',
                    arguments: conversation.id,
                  );
                },
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFF121212),
    );
  }
}
