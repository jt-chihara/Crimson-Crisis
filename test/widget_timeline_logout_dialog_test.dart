import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/timeline_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:crimsoncrisis/state/feed_providers.dart';
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
    );

class _FakeTimelineController extends TimelineController {
  @override
  Future<TimelineData> build() async =>
      TimelineData(items: [_feed('hello')], cursor: null);
}

class _LogoutSpySession extends SessionController {
  bool didLogout = false;

  @override
  Future<Session?> build() async => const Session(
        did: 'did:me',
        handle: 'me',
        accessJwt: 'a',
        refreshJwt: 'r',
        pds: 'https://example.com',
      );

  @override
  Future<void> logout() async {
    didLogout = true;
    // Do not call super.logout() to avoid accessing uninitialized storage in tests
    return Future.value();
  }
}

void main() {
  testWidgets('Logout shows confirmation and logs out on yes', (tester) async {
    final session = _LogoutSpySession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => session),
          timelineProvider.overrideWith(() => _FakeTimelineController()),
        ],
        child: const MaterialApp(home: TimelineScreen()),
      ),
    );

    // open dialog
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('ログアウトしますか？'), findsOneWidget);

    // confirm
    await tester.tap(find.widgetWithText(TextButton, 'はい'));
    await tester.pumpAndSettle();

    expect(session.didLogout, isTrue);
  });
}
