import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/notification.dart';
import 'package:crimsoncrisis/models/profile.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/connect_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ApiStub extends BskyApi {
  _ApiStub() : super(pds: 'https://example.com');

  @override
  Future<NotificationResponse> getNotifications({String? cursor, int limit = 50}) async {
    final items = <NotificationItem>[
      NotificationItem(
        uri: 'n1',
        cid: 'c1',
        authorDid: 'did:alice',
        authorHandle: 'alice',
        authorDisplayName: 'Alice',
        authorAvatar: null,
        reason: 'like',
        reasonSubject: null,
        text: 'hello',
        indexedAt: DateTime.now().toUtc(),
        isRead: false,
      ),
      NotificationItem(
        uri: 'n2',
        cid: 'c2',
        authorDid: 'did:bob',
        authorHandle: 'bob',
        authorDisplayName: 'Bob',
        authorAvatar: null,
        reason: 'mention',
        reasonSubject: null,
        text: '@me hi',
        indexedAt: DateTime.now().toUtc(),
        isRead: false,
      ),
      NotificationItem(
        uri: 'n3',
        cid: 'c3',
        authorDid: 'did:carol',
        authorHandle: 'carol',
        authorDisplayName: 'Carol',
        authorAvatar: null,
        reason: 'follow',
        reasonSubject: null,
        text: '',
        indexedAt: DateTime.now().toUtc(),
        isRead: false,
      ),
    ];
    return NotificationResponse(cursor: null, items: items);
  }

  @override
  Future<ActorProfile> getProfile({required String actor}) async => const ActorProfile(
        did: 'did:any',
        handle: 'any',
        displayName: 'Any',
        avatar: null,
        banner: null,
        description: null,
        followersCount: 0,
        followsCount: 0,
        postsCount: 0,
      );

  @override
  Future<TimelineResponse> getAuthorFeed({required String actor, String? cursor, int limit = 30}) async {
    return TimelineResponse(cursor: null, feed: []);
  }

  @override
  Future<List<FeedItem>> getPosts({required List<String> uris}) async {
    final uri = uris.isNotEmpty ? uris.first : 'p1';
    return [
      FeedItem(
        uri: uri,
        cid: 'cid-$uri',
        authorDid: 'did:bob',
        authorHandle: 'bob',
        authorDisplayName: 'Bob',
        authorAvatar: null,
        text: 'post body',
        createdAt: DateTime.now().toUtc(),
        likeCount: 0,
        repostCount: 0,
        replyCount: 0,
        viewerLike: null,
        viewerRepost: null,
        imageThumbUrls: const [],
        imageFullsizeUrls: const [],
      ),
    ];
  }
}

class _SessionStub extends SessionController {
  final BskyApi _api;
  _SessionStub(this._api);

  @override
  BskyApi? get api => _api;

  @override
  Future<Session?> build() async => const Session(
        did: 'did:me',
        handle: 'me',
        accessJwt: 'a',
        refreshJwt: 'r',
        pds: 'https://example.com',
      );
}

void main() {
  Future<void> _waitFor(WidgetTester tester, Finder f, {int maxTries = 30}) async {
    for (int i = 0; i < maxTries; i++) {
      if (tester.any(f)) return;
      await tester.pump(const Duration(milliseconds: 60));
    }
  }
  testWidgets('ConnectScreen shows Interactions and Mentions tabs and filters items', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(home: ConnectScreen()),
      ),
    );

    // Allow initial load
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Interactions tab: should contain like/follow/mention texts
    expect(find.text('liked your post'), findsWidgets);
    expect(find.text('followed you'), findsWidgets);
    expect(find.text('mentioned you'), findsWidgets);

    // Go to Mentions tab
    await tester.tap(find.text('Mentions'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Mentions tab shows mention items
    expect(find.text('mentioned you'), findsWidgets);
  });

  testWidgets('Tapping mention opens post detail', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(home: ConnectScreen()),
      ),
    );

    // Go to Mentions tab and wait
    await tester.tap(find.text('Mentions'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Ensure tile is visible and tap it
    // Mentionsタブ側のスクロール領域を使って可視化→タップ
    final scrollInMentions = find.byType(Scrollable).last;
    final mentionText = find.text('mentioned you').first;
    await tester.scrollUntilVisible(mentionText, 200.0, scrollable: scrollInMentions);
    final tile = find.descendant(of: scrollInMentions, matching: find.byType(InkWell)).first;
    await tester.tap(tile, warnIfMissed: false);
    await _waitFor(tester, find.text('post body'));
    expect(find.text('post body'), findsWidgets);
  });
}
