import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crimsoncrisis/api/bsky_api.dart';

void main() {
  group('BskyApi.getPostThread', () {
    test('parses ancestors and replies correctly', () async {
      final client = MockClient((http.Request req) async {
        if (req.url.path.endsWith('/xrpc/app.bsky.feed.getPostThread')) {
          expect(req.method, 'GET');
          final uri = req.url.queryParameters['uri'];
          expect(uri, 'at://did:me/app.bsky.feed.post/child');

          final response = {
            'thread': {
              'post': {
                'uri': 'at://did:me/app.bsky.feed.post/child',
                'cid': 'childCid',
                'author': {'did': 'did:me', 'handle': 'me', 'displayName': 'Me'},
                'record': {'text': 'child', 'createdAt': '2025-09-03T12:00:00Z'},
                'likeCount': 0,
                'repostCount': 0,
                'replyCount': 1,
                'viewer': {}
              },
              'parent': {
                'post': {
                  'uri': 'at://did:me/app.bsky.feed.post/parent',
                  'cid': 'parentCid',
                  'author': {'did': 'did:me', 'handle': 'me'},
                  'record': {'text': 'parent', 'createdAt': '2025-09-03T11:59:00Z'},
                  'likeCount': 0,
                  'repostCount': 0,
                  'replyCount': 1,
                  'viewer': {}
                },
                'parent': {
                  'post': {
                    'uri': 'at://did:me/app.bsky.feed.post/root',
                    'cid': 'rootCid',
                    'author': {'did': 'did:me', 'handle': 'me'},
                    'record': {'text': 'root', 'createdAt': '2025-09-03T11:58:00Z'},
                    'likeCount': 0,
                    'repostCount': 0,
                    'replyCount': 1,
                    'viewer': {}
                  }
                }
              },
              'replies': [
                {
                  'post': {
                    'uri': 'at://did:other/app.bsky.feed.post/reply1',
                    'cid': 'reply1Cid',
                    'author': {'did': 'did:other', 'handle': 'other'},
                    'record': {'text': 'reply1', 'createdAt': '2025-09-03T12:01:00Z'},
                    'likeCount': 0,
                    'repostCount': 0,
                    'replyCount': 0,
                    'viewer': {}
                  }
                }
              ]
            }
          };
          return http.Response(jsonEncode(response), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('not found', 404);
      });

      final api = BskyApi(client: client);
      final data = await api.getPostThread(uri: 'at://did:me/app.bsky.feed.post/child');
      expect(data.rootUri, 'at://did:me/app.bsky.feed.post/root');
      expect(data.rootCid, 'rootCid');
      expect(data.ancestors.length, 2); // root, parent
      expect(data.ancestors.first.text, 'root');
      expect(data.ancestors.last.text, 'parent');
      expect(data.replies.length, 1);
      expect(data.replies.first.text, 'reply1');
    });
  });

  group('BskyApi.createReply', () {
    test('sends reply payload with root and parent', () async {
      late Map<String, dynamic> captured;
      final client = MockClient((http.Request req) async {
        if (req.url.path.endsWith('/xrpc/com.atproto.repo.createRecord')) {
          expect(req.method, 'POST');
          captured = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'uri': 'at://did:me/app.bsky.feed.post/new', 'cid': 'newCid'}), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('not found', 404);
      });

      final api = BskyApi(client: client)..setTokens('a', 'r', 'did:me');
      final created = await api.createReply(
        text: 'hello',
        parentUri: 'parentUri',
        parentCid: 'parentCid',
        rootUri: 'rootUri',
        rootCid: 'rootCid',
      );
      expect(created.uri, isNotEmpty);
      expect(captured['collection'], 'app.bsky.feed.post');
      final record = captured['record'] as Map<String, dynamic>;
      final reply = record['reply'] as Map<String, dynamic>;
      expect(reply['root']['uri'], 'rootUri');
      expect(reply['root']['cid'], 'rootCid');
      expect(reply['parent']['uri'], 'parentUri');
      expect(reply['parent']['cid'], 'parentCid');
    });
  });
}

