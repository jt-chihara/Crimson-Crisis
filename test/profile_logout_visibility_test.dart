import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/profile.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/profile_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ApiStub extends BskyApi {
  _ApiStub() : super(pds: 'https://example.com');

  @override
  Future<ActorProfile> getProfile({required String actor}) async {
    return ActorProfile(
      did: actor,
      handle: actor == 'did:me' ? 'me' : 'other',
      displayName: actor == 'did:me' ? 'Me' : 'Other',
      avatar: null,
      banner: null,
      description: null,
      followersCount: 0,
      followsCount: 0,
      postsCount: 0,
    );
  }

  @override
  Future<TimelineResponse> getAuthorFeed({required String actor, String? cursor, int limit = 30}) async {
    return TimelineResponse(cursor: null, feed: []);
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
  testWidgets('shows logout button on own profile', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(home: ProfileScreen(actor: 'did:me')),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('does not show logout on other profile', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(home: ProfileScreen(actor: 'did:other')),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.logout), findsNothing);
  });
}
