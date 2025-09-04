import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crimsoncrisis/models/feed.dart';

void main() {
  test('parses app.bsky.embed.images view', () {
    final post = {
      'uri': 'u',
      'cid': 'c',
      'author': {'did': 'did:me', 'handle': 'me'},
      'record': {'text': 't', 'createdAt': '2025-09-03T12:00:00Z'},
      'embed': {
        'images': [
          {'thumb': 'https://t', 'fullsize': 'https://f'}
        ]
      },
      'likeCount': 0,
      'repostCount': 0,
      'replyCount': 0,
      'viewer': {}
    };

    final item = FeedItem.fromJson(post);
    expect(item.imageThumbUrls, ['https://t']);
    expect(item.imageFullsizeUrls, ['https://f']);
  });

  test('parses recordWithMedia view', () {
    final post = jsonDecode(jsonEncode({
      'uri': 'u',
      'cid': 'c',
      'author': {'did': 'did:me', 'handle': 'me'},
      'record': {'text': 't', 'createdAt': '2025-09-03T12:00:00Z'},
      'embed': {
        'media': {
          'images': [
            {'thumb': 'https://tt', 'fullsize': 'https://ff'}
          ]
        }
      },
      'likeCount': 0,
      'repostCount': 0,
      'replyCount': 0,
      'viewer': {}
    })) as Map<String, dynamic>;

    final item = FeedItem.fromJson(post);
    expect(item.imageThumbUrls, ['https://tt']);
    expect(item.imageFullsizeUrls, ['https://ff']);
  });
}

