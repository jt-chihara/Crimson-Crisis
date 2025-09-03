class TimelineResponse {
  final String? cursor;
  final List<FeedItem> feed;

  TimelineResponse({required this.cursor, required this.feed});

  factory TimelineResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['feed'] as List<dynamic>? ?? [])
        .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return TimelineResponse(cursor: json['cursor'] as String?, feed: items);
  }
}

class FeedItem {
  final String uri;
  final String cid;
  final String authorDid;
  final String authorHandle;
  final String? authorDisplayName;
  final String? authorAvatar;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final int repostCount;
  final int replyCount;
  final String? viewerLike;
  final String? viewerRepost;

  FeedItem({
    required this.uri,
    required this.cid,
    required this.authorDid,
    required this.authorHandle,
    required this.authorDisplayName,
    required this.authorAvatar,
    required this.text,
    required this.createdAt,
    required this.likeCount,
    required this.repostCount,
    required this.replyCount,
    required this.viewerLike,
    required this.viewerRepost,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final post = json['post'] as Map<String, dynamic>? ?? json;
    final author = post['author'] as Map<String, dynamic>? ?? {};
    final record = post['record'] as Map<String, dynamic>? ?? {};
    final viewer = post['viewer'] as Map<String, dynamic>? ?? {};
    return FeedItem(
      uri: post['uri'] as String? ?? '',
      cid: post['cid'] as String? ?? '',
      authorDid: author['did'] as String? ?? '',
      authorHandle: author['handle'] as String? ?? '',
      authorDisplayName: author['displayName'] as String?,
      authorAvatar: author['avatar'] as String?,
      text: record['text'] as String? ?? '',
      createdAt: DateTime.tryParse((record['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      likeCount: (post['likeCount'] as int?) ?? 0,
      repostCount: (post['repostCount'] as int?) ?? 0,
      replyCount: (post['replyCount'] as int?) ?? 0,
      viewerLike: viewer['like'] as String?,
      viewerRepost: viewer['repost'] as String?,
    );
  }
}

class CreatedRecord {
  final String uri;
  final String cid;

  CreatedRecord({required this.uri, required this.cid});

  factory CreatedRecord.fromJson(Map<String, dynamic> json) => CreatedRecord(
        uri: json['uri'] as String? ?? '',
        cid: json['cid'] as String? ?? '',
      );
}

