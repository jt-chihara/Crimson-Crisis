import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed.dart';
import '../state/auth_providers.dart';

class ReplyScreen extends ConsumerStatefulWidget {
  final FeedItem parent;
  final String rootUri;
  final String rootCid;

  const ReplyScreen({
    super.key,
    required this.parent,
    required this.rootUri,
    required this.rootCid,
  });

  @override
  ConsumerState<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends ConsumerState<ReplyScreen> {
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
      await api.createReply(
        text: text,
        parentUri: widget.parent.uri,
        parentCid: widget.parent.cid,
        rootUri: widget.rootUri,
        rootCid: widget.rootCid,
        langs: const ['ja'],
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('返信に失敗: $e')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('返信を書く'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('返信'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _text,
          maxLength: 300,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: '返信内容を入力...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

