import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/post_detail_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

FeedItem _feed({required String uri, required String cid, required String text}) {
  return FeedItem(
    uri: uri,
    cid: cid,
    authorDid: 'did:me',
    authorHandle: 'me',
    authorDisplayName: 'Me',
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
}

class _TestApi extends BskyApi {
  _TestApi() : super(pds: 'https://example.com');
  late PostThreadData last;
  @override
  Future<PostThreadData> getPostThread({required String uri, int depth = 50}) async {
    final data = PostThreadData(
      rootUri: 'rootUri',
      rootCid: 'rootCid',
      ancestors: [
        _feed(uri: 'root', cid: 'rc', text: 'ROOT'),
        _feed(uri: 'parent', cid: 'pc', text: 'PARENT'),
      ],
      replies: [
        _feed(uri: 'r1', cid: 'c1', text: 'REPLY1'),
      ],
    );
    last = data;
    return data;
  }
}

class _TestSessionController extends SessionController {
  final _TestApi apiImpl;
  _TestSessionController(this.apiImpl);

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
  testWidgets('PostDetailScreen shows ancestors and replies', (tester) async {
    final api = _TestApi();
    final item = _feed(uri: 'child', cid: 'cc', text: 'CHILD');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => _TestSessionController(api)),
        ],
        child: const MaterialApp(home: SizedBox()),
      ),
    );

    // Push PostDetailScreen on top of MaterialApp
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => _TestSessionController(api)),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          home: PostDetailScreen(item: item),
        ),
      ),
    );

    // allow async loading of thread
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('ROOT'), findsOneWidget);
    expect(find.text('PARENT'), findsOneWidget);
    expect(find.text('CHILD'), findsOneWidget);
    // It may be below the fold; scroll until visible
    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(find.text('REPLY1'), 200.0, scrollable: scrollable);
    expect(find.text('REPLY1'), findsWidgets);
  });
}
