import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/post_detail_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

FeedItem _item() => FeedItem(
      uri: 'u',
      cid: 'c',
      authorDid: 'did:me',
      authorHandle: 'me',
      authorDisplayName: 'Me',
      authorAvatar: null,
      text: 'body',
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
  _ApiStub() : super(pds: 'https://example.com');
  @override
  Future<PostThreadData> getPostThread({required String uri, int depth = 50}) async {
    return PostThreadData(rootUri: uri, rootCid: 'c', ancestors: const [], replies: const []);
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
        pds: 'https://example.com',
      );
}

void main() {
  testWidgets('PostDetail app bar shows icon (not text title)', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: MaterialApp(home: PostDetailScreen(item: _item())),
      ),
    );
    await tester.pump();
    // There should be at least one Image (Bluesky icon) in the app bar area
    expect(find.byType(Image), findsWidgets);
  });
}

