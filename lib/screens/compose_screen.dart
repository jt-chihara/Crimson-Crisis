import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';
import '../widgets/classic_app_bar.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _text = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_posting) return;
    final api = ref.read(sessionProvider.notifier).api;
    if (api == null) return;
    final text = _text.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await api.createPost(text: text, langs: const ['ja']);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('投稿に失敗: $e')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remain = 300 - _text.text.runes.length;
    return Scaffold(
      appBar: ClassicAppBar(
        leadingWidth: 96,
        leading: TextButton(
          onPressed: _posting ? null : () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('キャンセル', maxLines: 1, softWrap: false),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _posting || _text.text.trim().isEmpty ? null : _post,
            child: _posting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('送信'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE5E5E5),
      body: SafeArea(
        child: Column(
          children: [
            // Card-like composer container
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text area
                  Expanded(
                    child: TextField(
                      controller: _text,
                      onChanged: (_) => setState(() {}),
                      maxLength: 300,
                      maxLines: null,
                      minLines: 5,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'いまなにしてる？',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Image placeholder (not implemented)
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('画像添付は未実装です'))),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: const Icon(Icons.photo, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom tools row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.near_me, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 6),
                  Text('位置情報を追加', style: TextStyle(color: Colors.grey[700])),
                  const Spacer(),
                  Text(
                    '$remain',
                    style: TextStyle(
                      color: remain < 0 ? Colors.red : Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
