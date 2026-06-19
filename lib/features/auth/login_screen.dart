import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'test@test.com');
  final _password = TextEditingController(text: 'password123');
  bool _registerMode = false;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio.post(
        _registerMode ? '/auth/register' : '/auth/login',
        data: {
          'email': _email.text.trim(),
          'password': _password.text,
          if (_registerMode) 'displayName': 'Dopamine User',
        },
      );
      await ApiClient.instance.saveTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );
      if (mounted) context.go('/feed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dopamine Shop',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_registerMode ? 'Create account' : 'Sign in'),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _registerMode = !_registerMode),
                  child: Text(
                    _registerMode
                        ? 'I already have an account'
                        : 'Create new account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
