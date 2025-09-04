import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/bsky_api.dart';
import '../models/feed.dart';
import 'auth_providers.dart';

class TimelineData {
  final List<FeedItem> items;
  final String? cursor;
  const TimelineData({required this.items, required this.cursor});

  TimelineData copyWith({List<FeedItem>? items, String? cursor}) =>
      TimelineData(items: items ?? this.items, cursor: cursor);
}

final timelineProvider = AsyncNotifierProvider<TimelineController, TimelineData>(
  TimelineController.new,
);

class TimelineController extends AsyncNotifier<TimelineData> {
  BskyApi get _api {
    final api = ref.read(sessionProvider.notifier).api;
    if (api == null) {
      throw StateError('Not authenticated');
    }
    return api;
  }

  @override
  Future<TimelineData> build() async {
    // Load initial timeline
    final res = await _api.getTimeline(limit: 30);
    return TimelineData(items: res.feed, cursor: res.cursor);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await _api.getTimeline(limit: 30);
      return TimelineData(items: res.feed, cursor: res.cursor);
    });
  }

  Future<void> loadMore() async {
    final curr = state.valueOrNull;
    if (curr == null) return refresh();
    if (curr.cursor == null) return; // no more
    final prevItems = curr.items;
    final res = await _api.getTimeline(limit: 30, cursor: curr.cursor);
    final merged = [...prevItems, ...res.feed];
    state = AsyncData(TimelineData(items: merged, cursor: res.cursor));
  }

  Future<void> toggleLike(FeedItem item) async {
    final curr = state.valueOrNull;
    if (curr == null) return;
    final items = [...curr.items];
    final idx = items.indexWhere((e) => e.uri == item.uri);
    if (idx == -1) return;

    final current = items[idx];
    if (current.viewerLike != null) {
      // unlike
      await _api.unlike(likeUri: current.viewerLike!);
      items[idx] = FeedItem(
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
    } else {
      final created = await _api.like(subjectUri: current.uri, subjectCid: current.cid);
      items[idx] = FeedItem(
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
    }
    state = AsyncData(TimelineData(items: items, cursor: curr.cursor));
  }
}
