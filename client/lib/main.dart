import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/providers.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/conversations_screen.dart';

void main() {
  runApp(const ChatGPTApp());
}

class ChatGPTApp extends StatelessWidget {
  const ChatGPTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ConversationProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(context.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'ChatGPT Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
          brightness: Brightness.dark,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/conversations': (_) => const ConversationsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/chat') {
            final conversationId = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(conversationId: conversationId),
            );
          }
          return null;
        },
      ),
    );
  }
}

