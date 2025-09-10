import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';
import '../api/bsky_api.dart';
import '../models/feed.dart';
import '../widgets/post_tile.dart';
import '../widgets/classic_app_bar.dart';
import '../widgets/compose_sheet.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  static const _whatsHot = 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/whats-hot';

  final _items = <FeedItem>[];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;

  BskyApi get _api => ref.read(sessionProvider.notifier).api!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load(acceptLanguage: _acceptLanguage(context));
  }

  String _acceptLanguage(BuildContext context) {
    final l = Localizations.localeOf(context);
    final tag = (l.countryCode != null && l.countryCode!.isNotEmpty)
        ? '${l.languageCode}-${l.countryCode}'
        : l.languageCode;
    return '$tag,en;q=0.7';
  }

  Future<void> _load({String? acceptLanguage}) async {
    setState(() => _loading = true);
    try {
      final res = await _api.getFeed(
        feedUri: _whatsHot,
        limit: 30,
        acceptLanguage: acceptLanguage,
      );
      setState(() {
        _items
          ..clear()
          ..addAll(res.feed);
        _cursor = res.cursor;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _api.getFeed(feedUri: _whatsHot, limit: 30, cursor: _cursor, acceptLanguage: _acceptLanguage(context));
      setState(() {
        _items.addAll(res.feed);
        _cursor = res.cursor;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: ClassicAppBar(
        actions: [
          ClassicIconButton(
            icon: Icons.edit,
            onPressed: () async {
              final ok = await showComposeSheet(context);
              if (ok == true) await _load();
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                  final item = _items[index];
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
                    onAvatarTap: () {
                      final actor = item.authorDid.isNotEmpty
                          ? item.authorDid
                          : (item.authorHandle.isNotEmpty ? item.authorHandle : '');
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
            ),
    );
  }
}
