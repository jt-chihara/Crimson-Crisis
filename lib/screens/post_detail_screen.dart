import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/feed.dart';
import '../state/auth_providers.dart';
import 'profile_screen.dart';
import '../widgets/post_tile.dart';
import '../widgets/classic_app_bar.dart';
import 'reply_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final FeedItem item;
  const PostDetailScreen({super.key, required this.item});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late FeedItem _item;
  bool _togglingLike = false;
  List<FeedItem> _replies = [];
  bool _loadingReplies = true;
  String? _rootUri;
  String? _rootCid;
  List<FeedItem> _ancestors = [];

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    final api = ref.read(sessionProvider.notifier).api;
    if (api == null) return;
    setState(() => _loadingReplies = true);
    try {
      final data = await api.getPostThread(uri: _item.uri, depth: 50);
      if (!mounted) return;
      setState(() {
        _replies = data.replies;
        _rootUri = data.rootUri;
        _rootCid = data.rootCid;
        _ancestors = data.ancestors;
        _loadingReplies = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReplies = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_togglingLike) return;
    final api = ref.read(sessionProvider.notifier).api;
    if (api == null) return;
    setState(() => _togglingLike = true);
    try {
      if (_item.viewerLike != null) {
        await api.unlike(likeUri: _item.viewerLike!);
        setState(() {
          _item = FeedItem(
            uri: _item.uri,
            cid: _item.cid,
            authorDid: _item.authorDid,
            authorHandle: _item.authorHandle,
            authorDisplayName: _item.authorDisplayName,
            authorAvatar: _item.authorAvatar,
            text: _item.text,
            createdAt: _item.createdAt,
            likeCount: (_item.likeCount - 1).clamp(0, 1 << 31),
            repostCount: _item.repostCount,
            replyCount: _item.replyCount,
            viewerLike: null,
            viewerRepost: _item.viewerRepost,
          );
        });
      } else {
        final created = await api.like(subjectUri: _item.uri, subjectCid: _item.cid);
        setState(() {
          _item = FeedItem(
            uri: _item.uri,
            cid: _item.cid,
            authorDid: _item.authorDid,
            authorHandle: _item.authorHandle,
            authorDisplayName: _item.authorDisplayName,
            authorAvatar: _item.authorAvatar,
            text: _item.text,
            createdAt: _item.createdAt,
            likeCount: _item.likeCount + 1,
            repostCount: _item.repostCount,
            replyCount: _item.replyCount,
            viewerLike: created.uri,
            viewerRepost: _item.viewerRepost,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('いいねに失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _togglingLike = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = DateFormat('y/MM/dd HH:mm').format(_item.createdAt.toLocal());
    return Scaffold(
      appBar: const ClassicAppBar(),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _ancestors.length + 1 + 1 + 1 + (_loadingReplies ? 1 : _replies.length + 1),
        itemBuilder: (context, index) {
          if (index < _ancestors.length) {
            final anc = _ancestors[index];
            return PostTile(
              item: anc,
              onLike: () async {
                final api = ref.read(sessionProvider.notifier).api;
                if (api == null) return;
                final current = _ancestors[index];
                if (current.viewerLike != null) {
                  await api.unlike(likeUri: current.viewerLike!);
                  setState(() {
                    _ancestors[index] = FeedItem(
                      uri: current.uri,
                      cid: current.cid,
                      authorDid: current.authorDid,
                      authorHandle: current.authorHandle,
                      authorDisplayName: current.authorDisplayName,
                      authorAvatar: current.authorAvatar,
                      text: current.text,
                      createdAt: current.createdAt,
                      likeCount: (current.likeCount - 1).clamp(0, 1 << 31),
                      repostCount: current.repostCount,
                      replyCount: current.replyCount,
                      viewerLike: null,
                      viewerRepost: current.viewerRepost,
                    );
                  });
                } else {
                  final created = await api.like(subjectUri: current.uri, subjectCid: current.cid);
                  setState(() {
                    _ancestors[index] = FeedItem(
                      uri: current.uri,
                      cid: current.cid,
                      authorDid: current.authorDid,
                      authorHandle: current.authorHandle,
                      authorDisplayName: current.authorDisplayName,
                      authorAvatar: current.authorAvatar,
                      text: current.text,
                      createdAt: current.createdAt,
                      likeCount: current.likeCount + 1,
                      repostCount: current.repostCount,
                      replyCount: current.replyCount,
                      viewerLike: created.uri,
                      viewerRepost: current.viewerRepost,
                    );
                  });
                }
              },
              onMore: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PostDetailScreen(item: anc)),
                );
              },
              onAvatarTap: () {
                final actor = anc.authorDid.isNotEmpty
                    ? anc.authorDid
                    : (anc.authorHandle.isNotEmpty ? anc.authorHandle : '');
                if (actor.isEmpty) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(actor: actor),
                  ),
                );
              },
            );
          }
          final base = _ancestors.length;
          if (index == base + 0) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    final actor = _item.authorDid.isNotEmpty
                        ? _item.authorDid
                        : (_item.authorHandle.isNotEmpty ? _item.authorHandle : '');
                    if (actor.isEmpty) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(actor: actor),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: (_item.authorAvatar != null && _item.authorAvatar!.isNotEmpty)
                        ? NetworkImage(_item.authorAvatar!)
                        : null,
                    child: (_item.authorAvatar == null || _item.authorAvatar!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _item.authorDisplayName?.isNotEmpty == true
                            ? _item.authorDisplayName!
                            : '@${_item.authorHandle}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('@${_item.authorHandle}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            );
          }
          if (index == base + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item.text,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(ts, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ReplyScreen(
                                parent: _item,
                                rootUri: _rootUri ?? _item.uri,
                                rootCid: _rootCid ?? _item.cid,
                              ),
                            ),
                          );
                          if (ok == true) {
                            await _loadReplies();
                          }
                        },
                        icon: const Icon(Icons.mode_comment_outlined),
                      ),
                      const SizedBox(width: 6),
                      Text('${_item.replyCount}'),
                      const SizedBox(width: 18),
                      IconButton(
                        onPressed: null, // repost not implemented
                        icon: const Icon(Icons.repeat),
                      ),
                      const SizedBox(width: 6),
                      Text('${_item.repostCount}'),
                      const SizedBox(width: 18),
                      IconButton(
                        onPressed: _togglingLike ? null : _toggleLike,
                        icon: Icon(
                          Icons.favorite,
                          color: _item.viewerLike != null ? Colors.pink : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${_item.likeCount}'),
                    ],
                  ),
                  const Divider(height: 24),
                ],
              ),
            );
          }
          if (index == base + 2) {
            // write reply row
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              leading: const Icon(Icons.reply),
              title: const Text('返信を書く'),
              onTap: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ReplyScreen(
                      parent: _item,
                      rootUri: _rootUri ?? _item.uri,
                      rootCid: _rootCid ?? _item.cid,
                    ),
                  ),
                );
                if (ok == true) {
                  await _loadReplies();
                }
              },
            );
          }
          // replies section
          if (_loadingReplies) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (index == base + 3 + _replies.length) {
            return const SizedBox(height: 80);
          }
          final replyIdx = index - (base + 3);
          final reply = _replies[replyIdx];
          return PostTile(
            item: reply,
            onLike: () async {
              final api = ref.read(sessionProvider.notifier).api;
              if (api == null) return;
              final current = _replies[replyIdx];
              if (current.viewerLike != null) {
                await api.unlike(likeUri: current.viewerLike!);
                setState(() {
                  _replies[replyIdx] = FeedItem(
                    uri: current.uri,
                    cid: current.cid,
                    authorDid: current.authorDid,
                    authorHandle: current.authorHandle,
                    authorDisplayName: current.authorDisplayName,
                    authorAvatar: current.authorAvatar,
                    text: current.text,
                    createdAt: current.createdAt,
                    likeCount: (current.likeCount - 1).clamp(0, 1 << 31),
                    repostCount: current.repostCount,
                    replyCount: current.replyCount,
                    viewerLike: null,
                    viewerRepost: current.viewerRepost,
                  );
                });
              } else {
                final created = await api.like(subjectUri: current.uri, subjectCid: current.cid);
                setState(() {
                  _replies[replyIdx] = FeedItem(
                    uri: current.uri,
                    cid: current.cid,
                    authorDid: current.authorDid,
                    authorHandle: current.authorHandle,
                    authorDisplayName: current.authorDisplayName,
                    authorAvatar: current.authorAvatar,
                    text: current.text,
                    createdAt: current.createdAt,
                    likeCount: current.likeCount + 1,
                    repostCount: current.repostCount,
                    replyCount: current.replyCount,
                    viewerLike: created.uri,
                    viewerRepost: current.viewerRepost,
                  );
                });
              }
            },
            onMore: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(item: reply),
                ),
              );
            },
            onAvatarTap: () {
              final actor = reply.authorDid.isNotEmpty
                  ? reply.authorDid
                  : (reply.authorHandle.isNotEmpty ? reply.authorHandle : '');
              if (actor.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(actor: actor),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
