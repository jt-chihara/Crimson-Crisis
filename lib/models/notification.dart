class NotificationResponse {
  final String? cursor;
  final List<NotificationItem> items;
  const NotificationResponse({required this.cursor, required this.items});
}

class NotificationItem {
  final String uri;
  final String cid;
  final String authorDid;
  final String authorHandle;
  final String? authorDisplayName;
  final String? authorAvatar;
  final String reason; // like, repost, follow, mention, reply, quote
  final String? reasonSubject;
  final String text; // best effort: post text or empty
  final DateTime indexedAt;
  final bool isRead;
  final String? subjectText; // text of the liked/reposted/quoted post

  const NotificationItem({
    required this.uri,
    required this.cid,
    required this.authorDid,
    required this.authorHandle,
    required this.authorDisplayName,
    required this.authorAvatar,
    required this.reason,
    required this.reasonSubject,
    required this.text,
    required this.indexedAt,
    required this.isRead,
    this.subjectText,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final author = (json['author'] as Map?)?.cast<String, dynamic>() ?? {};
    final record = (json['record'] as Map?)?.cast<String, dynamic>() ?? {};
    return NotificationItem(
      uri: json['uri'] as String? ?? '',
      cid: json['cid'] as String? ?? '',
      authorDid: author['did'] as String? ?? '',
      authorHandle: author['handle'] as String? ?? '',
      authorDisplayName: author['displayName'] as String?,
      authorAvatar: author['avatar'] as String?,
      reason: json['reason'] as String? ?? '',
      reasonSubject: json['reasonSubject'] as String?,
      text: record['text'] as String? ?? '',
      indexedAt: DateTime.tryParse((json['indexedAt'] as String?) ?? '') ?? DateTime.now().toUtc(),
      isRead: (json['isRead'] as bool?) ?? false,
      subjectText: null,
    );
  }

  NotificationItem withSubjectText(String? t) => NotificationItem(
        uri: uri,
        cid: cid,
        authorDid: authorDid,
        authorHandle: authorHandle,
        authorDisplayName: authorDisplayName,
        authorAvatar: authorAvatar,
        reason: reason,
        reasonSubject: reasonSubject,
        text: text,
        indexedAt: indexedAt,
        isRead: isRead,
        subjectText: t,
      );
}
