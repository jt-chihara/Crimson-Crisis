import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';
import '../api/bsky_api.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _pds = TextEditingController(text: 'https://bsky.social');
  bool _showPassword = false;
  String? _lastErrorDetails;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _pds.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    final id = _identifier.text.trim();
    final pw = _password.text.trim();
    final pds = _pds.text.trim().isEmpty ? 'https://bsky.social' : _pds.text.trim();
    if (id.isEmpty || pw.isEmpty) return;
    try {
      await ref.read(sessionProvider.notifier).login(
            identifier: id,
            password: pw,
            pds: pds,
          );
    } catch (e) {
      if (!mounted) return;
      String summary = e.toString();
      String details = e.toString();
      if (e is BskyHttpException) {
        summary = e.toString();
        details = [
          'HTTP ${e.statusCode}${e.reason != null ? ' ${e.reason}' : ''}',
          if (e.code != null) 'code: ${e.code}',
          if (e.serverMessage != null) 'message: ${e.serverMessage}',
          if (e.body.isNotEmpty) 'body: ${e.body}',
        ].join('\n');
      }
      setState(() {
        _lastErrorDetails = details;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('ログインに失敗しました: $summary'),
          action: _lastErrorDetails == null
              ? null
              : SnackBarAction(
                  label: '詳細',
                  onPressed: _showErrorDialog,
                ),
        ),
      );
    }
  }

  void _showErrorDialog() {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final details = _lastErrorDetails;
    if (details == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('詳細ログ'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(details)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: details));
              nav.pop();
              messenger.showSnackBar(const SnackBar(content: Text('詳細をコピーしました')));
            },
            child: const Text('コピー'),
          ),
          TextButton(
            onPressed: () => nav.pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final loading = session.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Blueskyにログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Identifier (handle / email)'),
            const SizedBox(height: 8),
            TextField(
              controller: _identifier,
              enabled: !loading,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'your-handle.bsky.social または メール',
              ),
            ),
            const SizedBox(height: 16),
            const Text('App Password'),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              enabled: !loading,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'xxxx-xxxx-xxxx-xxxx',
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('PDS (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _pds,
              enabled: !loading,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://bsky.social',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading ? null : _onLogin,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: const Text('ログイン'),
              ),
            ),
            if (_lastErrorDetails != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _showErrorDialog,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('詳細ログを表示'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '注意: 本番アカウントではアプリパスワードの使用を推奨します。',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
