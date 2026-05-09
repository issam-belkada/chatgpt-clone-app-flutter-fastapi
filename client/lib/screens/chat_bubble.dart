import 'package:flutter/material.dart';

/// Simple reusable bubble — used if you render messages outside ChatScreen.
/// ChatScreen itself renders _MessageRow inline, which matches the GPT layout
/// (no bubble for assistant, pill bubble for user).
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant — no bubble, avatar + plain text
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              text,
              style: const TextStyle(color: Color(0xFFECECEC), fontSize: 15, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}