import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/discover_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<TimelineResponse> getFeed({required String feedUri, String? cursor, int limit = 30, String? acceptLanguage}) async {
    return TimelineResponse(cursor: null, feed: [_feed('A'), _feed('B')]);
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
  testWidgets('DiscoverScreen shows feed items', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(home: DiscoverScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
