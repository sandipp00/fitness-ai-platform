import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_client.dart';
import 'dashboard_screen.dart';
import 'privacy_policy_screen.dart';

class AuthScreen extends StatefulWidget {
  /// Optional notice shown above the form, e.g. after a session expires.
  final String? notice;

  const AuthScreen({super.key, this.notice});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final api = ApiClient.shared;
  bool registerMode = false;
  bool loading = false;
  String? error;

  Future<void> submit() async {
    final emailText = email.text.trim();
    if (emailText.isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your email and password.');
      return;
    }
    if (registerMode && password.text.length < 8) {
      setState(() => error = 'Use at least 8 characters for your password.');
      return;
    }

    setState(() { loading = true; error = null; });
    try {
      if (registerMode) {
        await api.register(emailText, password.text);
      } else {
        await api.login(emailText, password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(registerMode ? 'Create your account' : 'Welcome back'),
                    if (widget.notice != null) ...[
                      const SizedBox(height: 16),
                      Text(widget.notice!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ],
                    const SizedBox(height: 32),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: true,
                      autofillHints: [registerMode ? AutofillHints.newPassword : AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => loading ? null : submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: registerMode ? 'At least 8 characters' : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : submit,
                        child: Text(loading ? 'Please wait…' : registerMode ? 'Create account' : 'Sign in'),
                      ),
                    ),
                    TextButton(
                      onPressed: loading ? null : () => setState(() { registerMode = !registerMode; error = null; }),
                      child: Text(registerMode ? 'Already have an account? Sign in' : 'New here? Create an account'),
                    ),
                    if (registerMode)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        ),
                        child: const Text('By creating an account you agree to our Privacy Policy'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
