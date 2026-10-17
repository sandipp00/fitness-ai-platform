import 'package:flutter/material.dart';

import '../config.dart';

/// In-app privacy policy. Also shown when Health Connect asks the app to
/// explain why it needs health permissions.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const sections = <(String, String)>[
    (
      'What we collect',
      'Your email address and a securely hashed password; the profile details you enter '
          '(name, age, height, weight, goal, activity level, timezone); and, only if you connect '
          'a health app, daily totals of steps, active minutes, active calories, distance and '
          'sleep duration. We read health data; we never write to Health Connect or Apple Health.',
    ),
    (
      'How we use it',
      'Only to show your dashboard, progress trends, recovery scores, workout plans and coaching '
          'inside Kinetiq. We do not sell your data, use it for advertising, or share it with data '
          'brokers.',
    ),
    (
      'AI coach',
      'When you ask the coach a question, your question and a summary of your recent metrics '
          '(for example steps, active minutes and sleep hours) may be sent to our AI provider to '
          'generate an answer. Your email and name are not sent. The coach gives general wellness '
          'information and is not medical advice.',
    ),
    (
      'Storage and security',
      'Data is sent over encrypted connections (HTTPS) and stored on our servers. Sign-in tokens '
          'are kept in your device\'s secure storage.',
    ),
    (
      'Your choices',
      'You can disconnect health access at any time in Health Connect or Apple Health settings. '
          'You can delete your account and all associated data from Account & privacy in the app; '
          'deletion is immediate and permanent.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('${AppConfig.appName} respects your privacy.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          for (final (title, body) in sections) ...[
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
            const SizedBox(height: 18),
          ],
          if (AppConfig.privacyPolicyUrl.isNotEmpty)
            SelectableText('Full policy: ${AppConfig.privacyPolicyUrl}'),
          if (AppConfig.supportEmail.isNotEmpty)
            SelectableText('Questions: ${AppConfig.supportEmail}'),
        ],
      ),
    );
  }
}
