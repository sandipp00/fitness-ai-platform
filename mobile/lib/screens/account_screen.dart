import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/background_sync.dart';
import '../services/health_sync_service.dart';
import 'auth_screen.dart';
import 'privacy_policy_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final api = ApiClient.shared;
  bool busy = false;

  Future<void> _signedOut(String notice) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await const BackgroundSync().cancel();
    }
    await HealthSyncService.setConsent(false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthScreen(notice: notice)),
      (_) => false,
    );
  }

  Future<void> _run(Future<void> Function() action, String notice) async {
    setState(() => busy = true);
    try {
      await action();
      await _signedOut(notice);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || password.isEmpty) return;
    await _run(() => api.deleteAccount(password), 'Your account and all of its data were deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Account & privacy')),
      body: AbsorbPointer(
        absorbing: busy,
        child: ListView(
          children: [
            if (busy) const LinearProgressIndicator(),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign out'),
              onTap: () => _run(api.logout, 'You have signed out.'),
            ),
            ListTile(
              leading: const Icon(Icons.devices_other_rounded),
              title: const Text('Sign out of all devices'),
              subtitle: const Text('Ends every session, including this one'),
              onTap: () => _run(api.logoutEverywhere, 'You have signed out of all devices.'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: danger),
              title: Text('Delete account', style: TextStyle(color: danger)),
              subtitle: const Text('Permanently deletes your account and all health data'),
              onTap: _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final password = TextEditingController();

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account, profile and all synced health data. '
            'It cannot be undone.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Confirm with your password', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.of(context).pop(password.text),
          child: const Text('Delete permanently'),
        ),
      ],
    );
  }
}
