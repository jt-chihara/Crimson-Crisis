import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/profile.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/follow_list_screen.dart';
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
      followersCount: 2,
      followsCount: 2,
      postsCount: 0,
    );
  }

  @override
  Future<TimelineResponse> getAuthorFeed({required String actor, String? cursor, int limit = 30}) async {
    return TimelineResponse(cursor: null, feed: []);
  }

  @override
  Future<ActorListResponse> getFollows({required String actor, String? cursor, int limit = 50}) async {
    return ActorListResponse(cursor: null, items: [
      const ActorProfile(did: 'did:a', handle: 'alice', displayName: 'Alice', avatar: null, banner: null, description: null, followersCount: 0, followsCount: 0, postsCount: 0),
      const ActorProfile(did: 'did:b', handle: 'bob', displayName: 'Bob', avatar: null, banner: null, description: null, followersCount: 0, followsCount: 0, postsCount: 0),
    ]);
  }

  @override
  Future<ActorListResponse> getFollowers({required String actor, String? cursor, int limit = 50}) async {
    return ActorListResponse(cursor: null, items: [
      const ActorProfile(did: 'did:c', handle: 'carol', displayName: 'Carol', avatar: null, banner: null, description: null, followersCount: 0, followsCount: 0, postsCount: 0),
      const ActorProfile(did: 'did:d', handle: 'dave', displayName: 'Dave', avatar: null, banner: null, description: null, followersCount: 0, followsCount: 0, postsCount: 0),
    ]);
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
  testWidgets('FollowListScreen shows follows', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(
          home: FollowListScreen(actor: 'did:me', showFollowing: true),
        ),
      ),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Bob'), findsWidgets);
  });

  testWidgets('FollowListScreen shows followers', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(
          home: FollowListScreen(actor: 'did:me', showFollowing: false),
        ),
      ),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Carol'), findsWidgets);
    expect(find.text('Dave'), findsWidgets);
  });

  testWidgets('ProfileScreen tapping FOLLOWING/FOLLOWERS navigates to lists', (tester) async {
    final api = _ApiStub();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _SessionStub(api))],
        child: const MaterialApp(home: ProfileScreen(actor: 'did:me')),
      ),
    );
    // wait header render
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Tap FOLLOWING and verify list appears (Alice/Bob)
    // Ensure target visible
    await tester.scrollUntilVisible(find.text('FOLLOWING'), 200.0, scrollable: find.byType(Scrollable).first);
    final followingInk = find.ancestor(
      of: find.text('FOLLOWING'),
      matching: find.byType(InkWell),
    );
    await tester.tap(followingInk, warnIfMissed: false);
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Bob'), findsWidgets);

    // Back using our custom back icon
    final backFinder = find.byIcon(Icons.arrow_back);
    expect(backFinder, findsWidgets);
    await tester.tap(backFinder.first);
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Tap FOLLOWERS and verify list appears (Carol/Dave)
    await tester.scrollUntilVisible(find.text('FOLLOWERS'), 200.0, scrollable: find.byType(Scrollable).first);
    final followersInk = find.ancestor(
      of: find.text('FOLLOWERS'),
      matching: find.byType(InkWell),
    );
    await tester.tap(followersInk, warnIfMissed: false);
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Carol'), findsWidgets);
    expect(find.text('Dave'), findsWidgets);
  });
}
