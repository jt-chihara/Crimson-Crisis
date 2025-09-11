import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';
import '../api/bsky_api.dart';
import '../widgets/classic_app_bar.dart';

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
      backgroundColor: const Color(0xFFEFEFF1),
      appBar: const ClassicAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card-like input area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x16000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _LabeledField(
                      label: 'ユーザー名',
                      child: TextField(
                        controller: _identifier,
                        enabled: !loading,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'handle または メール',
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _LabeledField(
                      label: 'パスワード',
                      child: TextField(
                        controller: _password,
                        enabled: !loading,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'app password (xxxx-...)',
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // PDS (optional) small field beneath
              Row(
                children: [
                  const SizedBox(width: 4),
                  const Text('PDS:', style: TextStyle(color: Colors.black87)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pds,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: 'https://bsky.social',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Yellow gradient login button
              GestureDetector(
                onTap: loading ? null : _onLogin,
                child: Opacity(
                  opacity: loading ? 0.6 : 1.0,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE082), Color(0xFFFFC107)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text(
                            'ログイン',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
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
              const SizedBox(height: 14),
              const Text(
                'アカウントのパスワードではなくアプリパスワードを入れてください',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
