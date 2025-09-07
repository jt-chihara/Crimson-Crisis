import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/classic_app_bar.dart';
import '../widgets/classic_bottom_bar.dart';
import '../state/auth_providers.dart';
import '../api/bsky_api.dart';
import '../models/notification.dart';
import 'profile_screen.dart';
import 'compose_screen.dart';
import 'main_shell.dart';
import 'post_detail_screen.dart';

class ConnectScreen extends StatelessWidget {
  final bool showBottomBar;
  const ConnectScreen({super.key, this.showBottomBar = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ClassicAppBar(
          titleText: '',
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Interactions'),
              Tab(text: 'Mentions'),
            ],
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
        body: const TabBarView(
          children: [
            _NotificationList(onlyMentions: false),
            _NotificationList(onlyMentions: true),
          ],
        ),
        bottomNavigationBar: showBottomBar
            ? ClassicBottomBar(
                currentIndex: 1,
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
      ),
    );
  }
}

class _NotificationList extends ConsumerStatefulWidget {
  final bool onlyMentions;
  const _NotificationList({required this.onlyMentions});

  @override
  ConsumerState<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<_NotificationList> {
  final _items = <NotificationItem>[];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;

  BskyApi get _api => ref.read(sessionProvider.notifier).api!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _api.getNotifications(limit: 50);
      var list = _filter(res.items);
      final uris = list
          .where((e) => e.reasonSubject != null &&
              (e.reason == 'like' || e.reason == 'repost' || e.reason == 'quote'))
          .map((e) => e.reasonSubject!)
          .toSet()
          .toList();
      if (uris.isNotEmpty) {
        try {
          final texts = await _api.getPostsTexts(uris);
          if (!mounted) return;
          list = [
            for (final e in list)
              (e.reasonSubject != null && texts.containsKey(e.reasonSubject))
                  ? e.withSubjectText(texts[e.reasonSubject])
                  : e
          ];
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _cursor = res.cursor;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<NotificationItem> _filter(List<NotificationItem> items) {
    if (!widget.onlyMentions) return items;
    return items.where((e) => e.reason == 'mention' || e.reason == 'reply').toList();
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loadingMore) return;
    if (!mounted) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _api.getNotifications(limit: 50, cursor: _cursor);
      var append = _filter(res.items);
      final uris = append
          .where((e) => e.reasonSubject != null &&
              (e.reason == 'like' || e.reason == 'repost' || e.reason == 'quote'))
          .map((e) => e.reasonSubject!)
          .toSet()
          .toList();
      if (uris.isNotEmpty) {
        try {
          final texts = await _api.getPostsTexts(uris);
          if (!mounted) return;
          append = [
            for (final e in append)
              (e.reasonSubject != null && texts.containsKey(e.reasonSubject))
                  ? e.withSubjectText(texts[e.reasonSubject])
                  : e
          ];
        } catch (_) {}
      }
      final merged = [..._items, ...append];
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(merged);
        _cursor = res.cursor;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (_cursor != null) {
              _loadMore();
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox(height: 80);
          }
          final n = _items[index];
          return _NotificationTile(
            item: n,
            onTap: () async {
              if (n.reason == 'mention' || n.reason == 'reply') {
                final posts = await _api.getPosts(uris: [n.uri]);
                if (posts.isNotEmpty && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(item: posts.first),
                    ),
                  );
                }
              } else {
                final actor = n.authorDid.isNotEmpty ? n.authorDid : n.authorHandle;
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfileScreen(actor: actor)),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotificationTile({required this.item, required this.onTap});

  String _reasonText() {
    switch (item.reason) {
      case 'like':
        return 'liked your post';
      case 'repost':
        return 'reposted your post';
      case 'follow':
        return 'followed you';
      case 'mention':
        return 'mentioned you';
      case 'reply':
        return 'replied to you';
      default:
        return item.reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (item.authorAvatar != null && item.authorAvatar!.isNotEmpty)
                  ? NetworkImage(item.authorAvatar!)
                  : null,
              child: (item.authorAvatar == null || item.authorAvatar!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(_reasonText(), style: Theme.of(context).textTheme.bodySmall),
                  if ((item.subjectText != null && item.subjectText!.isNotEmpty) || item.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      (item.subjectText != null && item.subjectText!.isNotEmpty)
                          ? item.subjectText!
                          : item.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
