import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crimsoncrisis/state/feed_providers.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/session.dart';

class _TestSessionController extends SessionController {
  final BskyApi _testApi;
  _TestSessionController(this._testApi);

  @override
  BskyApi? get api => _testApi;

  @override
  Future<Session?> build() async => const Session(
        did: 'did:me',
        handle: 'me',
        accessJwt: 'a',
        refreshJwt: 'r',
        pds: 'https://bsky.social',
      );
}

void main() {
  ProviderContainer makeContainer(BskyApi api) {
    return ProviderContainer(overrides: [
      sessionProvider.overrideWith(() => _TestSessionController(api)),
    ]);
  }

  test('TimelineController loads and toggles like', () async {
    // Mock HTTP
    late Map<String, dynamic> lastBody;
    final client = MockClient((http.Request req) async {
      if (req.url.path.endsWith('/xrpc/app.bsky.feed.getTimeline')) {
        final res = {
          'cursor': null,
          'feed': [
            {
              'post': {
                'uri': 'p1',
                'cid': 'c1',
                'author': {'did': 'did:me', 'handle': 'me'},
                'record': {'text': 'hello', 'createdAt': '2025-09-03T12:00:00Z'},
                'embed': null,
                'likeCount': 0,
                'repostCount': 0,
                'replyCount': 0,
                'viewer': {}
              }
            }
          ]
        };
        return http.Response(jsonEncode(res), 200, headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/xrpc/com.atproto.repo.createRecord')) {
        lastBody = jsonDecode(req.body) as Map<String, dynamic>;
        // for like
        return http.Response(
            jsonEncode({
              'uri': 'at://did:me/app.bsky.feed.like/likeRkey',
              'cid': 'lcid'
            }),
            200,
            headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/xrpc/com.atproto.repo.deleteRecord')) {
        lastBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('not found', 404);
    });

    final api = BskyApi(client: client)..setTokens('a', 'r', 'did:me');
    final container = makeContainer(api);

    final data = await container.read(timelineProvider.future);
    final controller = container.read(timelineProvider.notifier);
    expect(data.items.length, 1);
    expect(data.items.first.text, 'hello');

    // like
    await controller.toggleLike(data.items.first);
    final liked = container.read(timelineProvider).value!
        .items.first; // state updated
    expect(liked.viewerLike, isNotNull);
    expect(lastBody['collection'], anyOf('app.bsky.feed.like', 'app.bsky.feed.post'));

    // unlike
    await controller.toggleLike(liked);
    final unliked = container.read(timelineProvider).value!.items.first;
    expect(unliked.viewerLike, isNull);
  });
}
