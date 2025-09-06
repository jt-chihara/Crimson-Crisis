import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/feed.dart';
import '../state/auth_providers.dart';
import 'profile_screen.dart';
import '../widgets/post_tile.dart';
import '../widgets/classic_app_bar.dart';
import 'reply_screen.dart';
import 'compose_screen.dart';
import '../widgets/classic_bottom_bar.dart';
import 'main_shell.dart';

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
            imageThumbUrls: _item.imageThumbUrls,
            imageFullsizeUrls: _item.imageFullsizeUrls,
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
            imageThumbUrls: _item.imageThumbUrls,
            imageFullsizeUrls: _item.imageFullsizeUrls,
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
      appBar: ClassicAppBar(
        leadingWidth: 72,
        leading: Tooltip(
          message: '戻る',
          child: ClassicIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        actions: [
          ClassicIconButton(
            icon: Icons.edit,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ComposeScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // ancestors + [card] + [stats repost] + [stats like] + [write reply] + replies + tail
        itemCount: _ancestors.length + 1 + 2 + 1 + (_loadingReplies ? 1 : _replies.length + 1),
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
                      imageThumbUrls: current.imageThumbUrls,
                      imageFullsizeUrls: current.imageFullsizeUrls,
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
                      imageThumbUrls: current.imageThumbUrls,
                      imageFullsizeUrls: current.imageFullsizeUrls,
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
            return _TweetDetailCard(
              item: _item,
              timestamp: ts,
              onReply: () async {
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
              onLike: _togglingLike ? null : _toggleLike,
              onAvatarTap: () {
                final actor = _item.authorDid.isNotEmpty
                    ? _item.authorDid
                    : (_item.authorHandle.isNotEmpty ? _item.authorHandle : '');
                if (actor.isEmpty) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfileScreen(actor: actor)),
                );
              },
            );
          }
          if (index == base + 1) {
            return _StatTile(label: 'リポスト', value: _item.repostCount);
          }
          if (index == base + 2) {
            return _StatTile(label: 'お気に入り', value: _item.likeCount);
          }
          if (index == base + 3) {
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
          if (index == base + 4 + _replies.length) {
            return const SizedBox(height: 80);
          }
          final replyIdx = index - (base + 4);
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
                    imageThumbUrls: current.imageThumbUrls,
                    imageFullsizeUrls: current.imageFullsizeUrls,
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
                    imageThumbUrls: current.imageThumbUrls,
                    imageFullsizeUrls: current.imageFullsizeUrls,
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
      bottomNavigationBar: ClassicBottomBar(
        currentIndex: 0,
        onTap: (i) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainShell(initialIndex: i)),
            (route) => false,
          );
        },
        items: const [
          ClassicBottomItem(icon: Icons.home, label: 'Home'),
          ClassicBottomItem(icon: Icons.alternate_email, label: 'Connect'),
          ClassicBottomItem(icon: Icons.tag, label: 'Discover'),
          ClassicBottomItem(icon: Icons.person, label: 'Me'),
        ],
      ),
    );
  }
}

class _DetailImageGrid extends StatelessWidget {
  final List<String> urls;
  const _DetailImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      if (urls.length == 1) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(urls.first, width: w, fit: BoxFit.cover),
        );
      }
      final size = (w - 8) / 2;
      final children = urls.take(4).map((u) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(u, width: size, height: size, fit: BoxFit.cover),
        );
      }).toList();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );
    });
  }
}

class _TweetDetailCard extends StatelessWidget {
  final FeedItem item;
  final String timestamp;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onAvatarTap;
  const _TweetDetailCard({
    required this.item,
    required this.timestamp,
    this.onReply,
    this.onLike,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: (item.authorAvatar != null && item.authorAvatar!.isNotEmpty)
                        ? NetworkImage(item.authorAvatar!)
                        : null,
                    child: (item.authorAvatar == null || item.authorAvatar!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.authorDisplayName?.isNotEmpty == true
                            ? item.authorDisplayName!
                            : '@${item.authorHandle}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('@${item.authorHandle}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.share, color: Colors.grey),
              ],
            ),
          ),
          if (item.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(item.text, style: Theme.of(context).textTheme.titleLarge),
            ),
          if (item.imageFullsizeUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _DetailImageGrid(urls: item.imageFullsizeUrls),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: const Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply, color: Colors.grey),
                ),
                const Spacer(),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.repeat, color: Colors.grey),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    Icons.star,
                    color: item.viewerLike != null ? Colors.amber : Colors.grey,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.share, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x16000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        title: Text(label),
        trailing: Text('${value.toString()}'),
      ),
    );
  }
}
