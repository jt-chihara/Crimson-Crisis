import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/profile_providers.dart';
import '../state/auth_providers.dart';
import '../api/bsky_api.dart';
import '../models/feed.dart';
import '../models/profile.dart';
import '../widgets/post_tile.dart';
import '../widgets/classic_app_bar.dart';
import 'post_detail_screen.dart';
import 'compose_screen.dart';
import '../widgets/classic_bottom_bar.dart';
import 'main_shell.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String actor; // did or handle
  final bool showBottomBar;
  const ProfileScreen({super.key, required this.actor, this.showBottomBar = true});

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
        leadingWidth: 72,
        leading: !isMe
            ? Tooltip(
                message: '戻る',
                child: ClassicIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              )
            : null,
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
            : [
                ClassicIconButton(
                  icon: Icons.edit,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ComposeScreen()),
                  ),
                ),
              ],
      ),
      body: asyncProfile.when(
        data: (p) => ListView.builder(
          itemCount: 1 + _items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Use the same classic header for both Me and others
              return _MeHeader(profile: p);
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
      bottomNavigationBar: widget.showBottomBar
          ? ClassicBottomBar(
        currentIndex: isMe ? 3 : 0,
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
      )
          : null,
    );
  }
}

class _MeHeader extends StatelessWidget {
  final ActorProfile profile;
  const _MeHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner + avatar centered
        SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (profile.banner != null && profile.banner!.isNotEmpty)
                Image.network(profile.banner!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x66000000)],
                  ),
                ),
              ),
              // Avatar
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundImage: (profile.avatar != null && profile.avatar!.isNotEmpty)
                        ? NetworkImage(profile.avatar!)
                        : null,
                    child: (profile.avatar == null || profile.avatar!.isEmpty)
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(profile.displayName ?? '@${profile.handle}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87)),
              Text('@${profile.handle}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Stats card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Color(0x16000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              _StatColumn(label: 'TWEETS', value: profile.postsCount),
              _divider(),
              _StatColumn(
                label: 'FOLLOWING',
                value: profile.followsCount,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FollowListScreen(actor: profile.did.isNotEmpty ? profile.did : profile.handle, showFollowing: true),
                    ),
                  );
                },
              ),
              _divider(),
              _StatColumn(
                label: 'FOLLOWERS',
                value: profile.followersCount,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FollowListScreen(actor: profile.did.isNotEmpty ? profile.did : profile.handle, showFollowing: false),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }

  Widget _divider() => const SizedBox(
        width: 1,
        height: 28,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
        ),
      );
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;
  const _StatColumn({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 0.5, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  final ActorProfile profile;
  const _SimpleHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.banner != null)
          Image.network(
            profile.banner!,
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
                backgroundImage: (profile.avatar != null && profile.avatar!.isNotEmpty)
                    ? NetworkImage(profile.avatar!)
                    : null,
                child: (profile.avatar == null || profile.avatar!.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName ?? '@${profile.handle}',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('@${profile.handle}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Stats row for others as well
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              _StatColumn(label: 'TWEETS', value: profile.postsCount),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FollowListScreen(actor: profile.did.isNotEmpty ? profile.did : profile.handle, showFollowing: true),
                      ),
                    );
                  },
                  child: Text('FOLLOWING ${profile.followsCount}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FollowListScreen(actor: profile.did.isNotEmpty ? profile.did : profile.handle, showFollowing: false),
                      ),
                    );
                  },
                  child: Text('FOLLOWERS ${profile.followersCount}'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
