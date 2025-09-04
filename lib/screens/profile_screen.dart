import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/profile_providers.dart';
import '../state/auth_providers.dart';
import '../api/bsky_api.dart';
import '../models/feed.dart';
import '../widgets/post_tile.dart';
import '../widgets/classic_app_bar.dart';
import 'post_detail_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String actor; // did or handle
  const ProfileScreen({super.key, required this.actor});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<FeedItem> _items = [];
  String? _cursor;
  bool _loadingFeed = true;
  bool _loadingMore = false;

  BskyApi get _api => ref.read(sessionProvider.notifier).api!;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _loadingFeed = true);
    try {
      final res = await _api.getAuthorFeed(actor: widget.actor, limit: 30);
      setState(() {
        _items = res.feed;
        _cursor = res.cursor;
        _loadingFeed = false;
      });
    } catch (_) {
      setState(() => _loadingFeed = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _api.getAuthorFeed(actor: widget.actor, limit: 30, cursor: _cursor);
      setState(() {
        _items = [..._items, ...res.feed];
        _cursor = res.cursor;
      });
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleLike(FeedItem item) async {
    final idx = _items.indexWhere((e) => e.uri == item.uri);
    if (idx == -1) return;
    final current = _items[idx];
    if (current.viewerLike != null) {
      await _api.unlike(likeUri: current.viewerLike!);
      setState(() {
        _items[idx] = FeedItem(
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
      final created = await _api.like(subjectUri: current.uri, subjectCid: current.cid);
      setState(() {
        _items[idx] = FeedItem(
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
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(profileProvider(widget.actor));
    final ses = ref.watch(sessionProvider).valueOrNull;
    final isMe = ses != null && (widget.actor == ses.did || widget.actor == ses.handle);
    return Scaffold(
      appBar: ClassicAppBar(
        actions: isMe
            ? [
                ClassicIconButton(
                  icon: Icons.logout,
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('確認'),
                        content: const Text('ログアウトしますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('はい'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(sessionProvider.notifier).logout();
                    }
                  },
                ),
              ]
            : null,
      ),
      body: asyncProfile.when(
        data: (p) => ListView.builder(
          itemCount: 1 + _items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.banner != null)
                    Image.network(
                      p.banner!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 8),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: (p.avatar != null && p.avatar!.isNotEmpty)
                              ? NetworkImage(p.avatar!)
                              : null,
                          child: (p.avatar == null || p.avatar!.isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.displayName ?? '@${p.handle}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text('@${p.handle}',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              if (p.description != null && p.description!.isNotEmpty)
                                Text(p.description!),
                              const SizedBox(height: 12),
                              DefaultTextStyle(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Colors.black54),
                                child: Row(
                                  children: [
                                    Text('Posts ${p.postsCount}'),
                                    const SizedBox(width: 12),
                                    Text('Following ${p.followsCount}'),
                                    const SizedBox(width: 12),
                                    Text('Followers ${p.followersCount}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            }
            final feedIndex = index - 1;
            if (feedIndex == _items.length) {
              if (_loadingFeed) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_cursor != null) {
                _loadMore();
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox(height: 80);
            }

            final item = _items[feedIndex];
            return PostTile(
              item: item,
              onLike: () => _toggleLike(item),
              onMore: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(item: item),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗: $e')),
      ),
    );
  }
}
