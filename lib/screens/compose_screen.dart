import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';
import '../widgets/classic_app_bar.dart';
import '../widgets/classic_bottom_bar.dart';
import 'main_shell.dart';
import 'package:image_picker/image_picker.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _text = TextEditingController();
  bool _posting = false;
  final List<XFile> _images = [];

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
        for (final x in _images.take(4)) {
          final bytes = await x.readAsBytes();
          final mime = _mimeFromPath(x.path);
          final blob = await api.uploadBlob(bytes: bytes, contentType: mime);
          imgs.add({'alt': '', 'image': blob});
        }
        embed = {r'$type': 'app.bsky.embed.images', 'images': imgs};
      }
      await api.createPost(text: text, langs: const ['ja'], embed: embed);
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

  String _mimeFromPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final remain = 300 - _text.text.runes.length;
    final canSend = (_text.text.trim().isNotEmpty || _images.isNotEmpty) && !_posting;
    return Scaffold(
      appBar: ClassicAppBar(
        leadingWidth: 72,
        leading: Tooltip(
          message: 'キャンセル',
          child: ClassicIconButton(
            icon: Icons.close,
            onPressed: _posting ? null : () => Navigator.of(context).maybePop(),
          ),
        ),
        actions: [
          Tooltip(
            message: '送信',
            child: Opacity(
              opacity: canSend ? 1.0 : 0.5,
              child: ClassicIconButton(
                onPressed: canSend ? _post : null,
                child: _posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
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
                  _ImagePickerBox(
                    images: _images,
                    onAdd: () async {
                      final picker = ImagePicker();
                      final picks = await picker.pickMultiImage(imageQuality: 90, maxWidth: 2048, maxHeight: 2048);
                      if (picks.isEmpty) return;
                      setState(() {
                        _images
                          ..clear()
                          ..addAll(picks.take(4));
                      });
                    },
                    onRemove: (idx) {
                      setState(() {
                        _images.removeAt(idx);
                      });
                    },
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
      // Bottom bar is provided by MainShell to keep tab state fixed
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  const _ImagePickerBox({required this.images, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return GestureDetector(
        onTap: onAdd,
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
      );
    }
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          for (int i = 0; i < images.length && i < 4; i++) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(File(images[i].path), width: 96, height: 72, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => onRemove(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.photo_library),
            label: const Text('写真'),
          ),
        ],
      ),
    );
  }
}
