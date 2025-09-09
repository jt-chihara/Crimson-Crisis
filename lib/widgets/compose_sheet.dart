import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';

Future<bool?> showComposeSheet(
  BuildContext context, {
  bool reply = false,
  String? parentUri,
  String? parentCid,
  String? rootUri,
  String? rootCid,
}) {
  assert(
    !reply || (parentUri != null && parentCid != null && rootUri != null && rootCid != null),
    'reply=true の場合は parent/root の URI と CID を指定してください',
  );
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ComposeSheet(
      reply: reply,
      parentUri: parentUri,
      parentCid: parentCid,
      rootUri: rootUri,
      rootCid: rootCid,
    ),
  );
}

class _ComposeSheet extends ConsumerStatefulWidget {
  final bool reply;
  final String? parentUri;
  final String? parentCid;
  final String? rootUri;
  final String? rootCid;
  const _ComposeSheet({
    this.reply = false,
    this.parentUri,
    this.parentCid,
    this.rootUri,
    this.rootCid,
  });

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  final _text = TextEditingController();
  final List<File> _images = [];
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
    if (text.isEmpty && _images.isEmpty) return;
    setState(() => _posting = true);
    try {
      Map<String, dynamic>? embed;
      if (_images.isNotEmpty) {
        final imgs = <Map<String, dynamic>>[];
        for (final f in _images.take(4)) {
          final bytes = await f.readAsBytes();
          final mime = _mimeFromPath(f.path);
          final blob = await api.uploadBlob(bytes: bytes, contentType: mime);
          imgs.add({'alt': '', 'image': blob});
        }
        embed = {r'$type': 'app.bsky.embed.images', 'images': imgs};
      }
      if (widget.reply) {
        await api.createReply(
          text: text,
          parentUri: widget.parentUri!,
          parentCid: widget.parentCid!,
          rootUri: widget.rootUri!,
          rootCid: widget.rootCid!,
          langs: const ['ja'],
          embed: embed,
        );
      } else {
        await api.createPost(text: text, langs: const ['ja'], embed: embed);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投稿に失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  String _mimeFromPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  void _showLocationInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お知らせ'),
        content: const Text('これはダミーです。blueskyは位置情報を追加できません'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final canSend = (_text.text.trim().isNotEmpty || _images.isNotEmpty) && !_posting;
    final remain = 300 - _text.text.runes.length;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, -4)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: _posting ? null : () => Navigator.of(context).maybePop(),
                      child: const Text('キャンセル'),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: canSend ? 1.0 : 0.5,
                      child: FilledButton(
                        onPressed: canSend ? _post : null,
                        child: _posting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('送信'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _text,
                  onChanged: (_) => setState(() {}),
                  maxLength: 300,
                  maxLines: null,
                  minLines: 5,
                  decoration: InputDecoration(
                    counterText: '',
                    border: const OutlineInputBorder(),
                    hintText: widget.reply ? '返信内容を入力...' : 'いまなにしてる？',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: _showLocationInfo,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.near_me, color: Colors.grey, size: 20),
                          SizedBox(width: 6),
                          Text('位置情報を追加'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$remain',
                      style: TextStyle(
                        color: remain < 0 ? Colors.red : Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
