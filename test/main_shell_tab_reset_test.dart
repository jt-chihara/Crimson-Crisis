import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crimsoncrisis/screens/main_shell.dart';
import 'package:crimsoncrisis/widgets/post_tile.dart';
import 'package:crimsoncrisis/screens/post_detail_screen.dart';
import 'package:crimsoncrisis/state/feed_providers.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/notification.dart';
import 'package:crimsoncrisis/models/session.dart';

// A minimal fake TimelineController that returns one post.
class _FakeTimelineController extends TimelineController {
  @override
  Future<TimelineData> build() async {
    final now = DateTime.now().toUtc();
    final item = FeedItem(
      uri: 'at://example/post/1',
      cid: 'cid',
      authorDid: 'did:example:alice',
      authorHandle: 'alice.test',
      authorDisplayName: 'Alice',
      authorAvatar: null,
      text: 'Hello',
      createdAt: now,
      likeCount: 0,
      repostCount: 0,
      replyCount: 0,
      viewerLike: null,
      viewerRepost: null,
      imageThumbUrls: const [],
      imageFullsizeUrls: const [],
    );
    return TimelineData(items: [item], cursor: null);
  }
}

// Fake API so ConnectScreen etc. don't perform network requests during build.
class _FakeBskyApi extends BskyApi {
  _FakeBskyApi() : super(pds: 'https://example.invalid');

  @override
  Future<NotificationResponse> getNotifications({String? cursor, int limit = 50}) async {
    return const NotificationResponse(cursor: null, items: []);
  }

  @override
  Future<Map<String, String>> getPostsTexts(List<String> uris) async => {};

  @override
  Future<List<FeedItem>> getPosts({required List<String> uris}) async => const [];

  @override
  Future<PostThreadData> getPostThread({required String uri, int depth = 50}) async {
    return PostThreadData(rootUri: uri, rootCid: '', ancestors: const [], replies: const []);
  }
}

class _FakeSessionController extends SessionController {
  final _api = _FakeBskyApi();

  @override
  Future<void> logout() async {}

  @override
  Future<Session?> build() async {
    // No need to return a real session for this test.
    return null;
  }

  @override
  BskyApi? get api => _api;
}

void main() {
  testWidgets('tapping active tab pops to its root', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timelineProvider.overrideWith(_FakeTimelineController.new),
          sessionProvider.overrideWith(_FakeSessionController.new),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );

    // Wait for first frame
    await tester.pumpAndSettle();

    // There should be one post in the timeline.
    expect(find.byType(PostTile), findsOneWidget);

    // Tap the tile to navigate to detail screen (pushes onto tab navigator).
    await tester.tap(find.byType(PostTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(PostDetailScreen), findsOneWidget);

    // Tap the currently selected bottom item (Home) to pop to root.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(PostDetailScreen), findsNothing);
  });
}
