import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/profile.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/profile_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

FeedItem _feed(String text) => FeedItem(
      uri: 'u',
      cid: 'c',
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

class _LogoutSpySession extends SessionController {
  bool didLogout = false;
  final BskyApi apiImpl;
  _LogoutSpySession(this.apiImpl);

  @override
  Future<Session?> build() async => const Session(
        did: 'did:me',
        handle: 'me',
        accessJwt: 'a',
        refreshJwt: 'r',
        pds: 'https://example.com',
      );

  @override
  BskyApi? get api => apiImpl;

  @override
  Future<void> logout() async {
    didLogout = true;
    // Do not call super.logout() to avoid accessing uninitialized storage in tests
    return Future.value();
  }
}

void main() {
  testWidgets('Logout shows confirmation and logs out on yes', (tester) async {
    final api = _TestApi();
    final session = _LogoutSpySession(api);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => session)],
        child: const MaterialApp(home: ProfileScreen(actor: 'did:me')),
      ),
    );

    // Wait for app bar actions to appear
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // open dialog
    final logoutFinder = find.byIcon(Icons.logout);
    expect(logoutFinder, findsOneWidget);
    await tester.tap(logoutFinder);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('ログアウトしますか？'), findsOneWidget);

    // confirm
    await tester.tap(find.widgetWithText(TextButton, 'はい'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(session.didLogout, isTrue);
  });
}

class _TestApi extends BskyApi {
  _TestApi() : super(pds: 'https://example.com');
  @override
  Future<TimelineResponse> getAuthorFeed({required String actor, String? cursor, int limit = 30}) async {
    return TimelineResponse(cursor: null, feed: []);
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
      postsCount: 0,
    );
  }
}
