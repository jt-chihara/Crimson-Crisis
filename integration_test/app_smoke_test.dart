import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crimsoncrisis/app.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/models/profile.dart';

FeedItem _feed(String text) => FeedItem(
      uri: 'at://u/$text',
      cid: 'c',
      authorDid: 'did:test',
      authorHandle: 'test',
      authorDisplayName: 'T',
      authorAvatar: null,
      text: text,
      createdAt: DateTime.now().toUtc(),
      likeCount: 0,
      repostCount: 0,
      replyCount: 0,
      viewerLike: null,
      viewerRepost: null,
      imageThumbUrls: const [],
      imageFullsizeUrls: const [],
    );

class _ApiStub extends BskyApi {
  _ApiStub() : super(pds: 'https://example.invalid');

  @override
  Future<TimelineResponse> getTimeline({String? cursor, int limit = 30}) async {
    return TimelineResponse(cursor: null, feed: [_feed('TL1'), _feed('TL2')]);
  }

  @override
  Future<TimelineResponse> getFeed({
    required String feedUri,
    String? cursor,
    int limit = 30,
    String? acceptLanguage,
  }) async {
    return TimelineResponse(cursor: null, feed: [_feed('HOT1'), _feed('HOT2')]);
  }

  @override
  Future<ActorProfile> getProfile({required String actor}) async {
    return const ActorProfile(
      did: 'did:me',
      handle: 'me',
      displayName: 'Me',
      avatar: null,
      banner: null,
      description: null,
      followersCount: 0,
      followsCount: 0,
      postsCount: 1,
    );
  }

  @override
  Future<TimelineResponse> getAuthorFeed({required String actor, String? cursor, int limit = 30}) async {
    return TimelineResponse(cursor: null, feed: [_feed('MY POST')]);
  }
}

class _SessionStub extends SessionController {
  final _ApiStub apiImpl;
  _SessionStub(this.apiImpl);

  @override
  BskyApi? get api => apiImpl;

  @override
  Future<Session?> build() async => const Session(
        did: 'did:me',
        handle: 'me',
        accessJwt: 'a',
        refreshJwt: 'r',
        pds: 'https://example.invalid',
      );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: bottom tabs and discover feed', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const AppRoot(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);

    // switch to Discover and see stubbed items
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('HOT1'), findsOneWidget);
    expect(find.text('HOT2'), findsOneWidget);

    // switch to Me and verify profile header and one post
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('@me'), findsOneWidget);
    expect(find.text('MY POST'), findsOneWidget);
  });
}
