import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final controller = TextEditingController();
  final api = const ApiClient();
  final session = const Session();

  final messages = <_Message>[];
  bool sending = false;

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    controller.clear();
    setState(() {
      messages.add(_Message(text, true));
      sending = true;
    });

    try {
      final token = await session.getToken();
      if (token == null) throw Exception('Session expired');

      final result = await api.chat(token, text);
      if (!mounted) return;

      setState(() {
        messages.add(_Message(
          result['answer']?.toString() ?? 'No response.',
          false,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add(_Message('Coach error: $e', false));
      });
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final message = messages[index];
                return Align(
                  alignment: message.user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 330),
                        child: Text(message.text),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask your fitness coach…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : send,
                    icon: const Icon(Icons.send),
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

class _Message {
  final String text;
  final bool user;

  const _Message(this.text, this.user);
}
