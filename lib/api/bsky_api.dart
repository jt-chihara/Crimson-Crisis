import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session.dart';
import '../models/feed.dart';
import '../models/profile.dart';

class PostThreadData {
  final String rootUri;
  final String rootCid;
  final List<FeedItem> ancestors; // root -> ... -> parent
  final List<FeedItem> replies; // all replies under the target
  PostThreadData({
    required this.rootUri,
    required this.rootCid,
    required this.ancestors,
    required this.replies,
  });
}

class BskyApi {
  BskyApi({String? pds, http.Client? client})
      : _base = _normalizePds(pds ?? 'https://bsky.social'),
        _client = client ?? http.Client();

  final String _base; // e.g. https://bsky.social
  final http.Client _client;

  String? _accessJwt;
  String? _refreshJwt;
  String? _did;

  static String _normalizePds(String pds) {
    if (pds.endsWith('/')) return pds.substring(0, pds.length - 1);
    return pds;
  }

  void setTokens(String accessJwt, String refreshJwt, String did) {
    _accessJwt = accessJwt;
    _refreshJwt = refreshJwt;
    _did = did;
  }

  Uri _xrpc(String nsid, [Map<String, String>? params]) {
    final uri = Uri.parse('$_base/xrpc/$nsid');
    if (params == null || params.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...params});
  }

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (auth && _accessJwt != null) {
      headers['Authorization'] = 'Bearer $_accessJwt';
    }
    return headers;
  }

  Future<http.Response> _post(String nsid, Map<String, dynamic> body,
      {bool auth = false}) async {
    final res = await _client.post(
      _xrpc(nsid),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    _throwIfError(res);
    return res;
  }

  Future<http.Response> _get(String nsid, Map<String, String> params,
      {bool auth = false}) async {
    final res = await _client.get(
      _xrpc(nsid, params),
      headers: _headers(auth: auth),
    );
    _throwIfError(res);
    return res;
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? code;
    String? serverMessage;
    try {
      final m = jsonDecode(res.body);
      if (m is Map<String, dynamic>) {
        code = m['error'] as String?;
        serverMessage = m['message'] as String?;
      }
    } catch (_) {}
    throw BskyHttpException(
      statusCode: res.statusCode,
      body: res.body,
      reason: res.reasonPhrase,
      code: code,
      serverMessage: serverMessage,
    );
  }

  // Auth
  Future<Session> createSession({
    required String identifier, // handle or email
    required String password, // app password recommended
  }) async {
    final res = await _post('com.atproto.server.createSession', {
      'identifier': identifier,
      'password': password,
    });
    final map = jsonDecode(res.body) as Map<String, dynamic>;

    final session = Session(
      did: map['did'] as String,
      handle: map['handle'] as String? ?? identifier,
      accessJwt: map['accessJwt'] as String,
      refreshJwt: map['refreshJwt'] as String,
      pds: _base,
    );
    setTokens(session.accessJwt, session.refreshJwt, session.did);
    return session;
  }

  Future<Session> refreshSession() async {
    final res = await _client.post(
      _xrpc('com.atproto.server.refreshSession'),
      headers: {
        ..._headers(),
        if (_refreshJwt != null) 'Authorization': 'Bearer $_refreshJwt',
      },
    );
    _throwIfError(res);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final session = Session(
      did: map['did'] as String? ?? _did ?? '',
      handle: map['handle'] as String? ?? '',
      accessJwt: map['accessJwt'] as String,
      refreshJwt: map['refreshJwt'] as String,
      pds: _base,
    );
    setTokens(session.accessJwt, session.refreshJwt, session.did);
    return session;
  }

  // Feed: timeline
  Future<TimelineResponse> getTimeline({String? cursor, int limit = 30}) async {
    final res = await _get('app.bsky.feed.getTimeline', {
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return TimelineResponse.fromJson(map);
  }

  // Actor: profile
  Future<ActorProfile> getProfile({required String actor}) async {
    final res = await _get('app.bsky.actor.getProfile', {
      'actor': actor,
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return ActorProfile.fromJson(map);
  }

  // Feed: author feed
  Future<TimelineResponse> getAuthorFeed({
    required String actor,
    String? cursor,
    int limit = 30,
  }) async {
    final res = await _get('app.bsky.feed.getAuthorFeed', {
      'actor': actor,
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return TimelineResponse.fromJson(map);
  }

  // Feed: post thread (replies)
  Future<PostThreadData> getPostThread({required String uri, int depth = 50}) async {
    final res = await _get('app.bsky.feed.getPostThread', {
      'uri': uri,
      'depth': '$depth',
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final thread = map['thread'];
    if (thread is! Map<String, dynamic>) {
      return PostThreadData(rootUri: uri, rootCid: '', ancestors: const [], replies: const []);
    }

    // climb to root through parent chain
    Map<String, dynamic> node = thread;
    Map<String, dynamic> rootNode = node;
    final List<FeedItem> ancestorsRev = [];
    while (true) {
      final parent = node['parent'];
      if (parent is Map<String, dynamic>) {
        final ppost = parent['post'];
        if (ppost is Map<String, dynamic>) {
          try { ancestorsRev.add(FeedItem.fromJson(ppost)); } catch (_) {}
        }
        rootNode = parent;
        node = parent;
      } else {
        break;
      }
    }
    String rootUri = uri;
    String rootCid = '';
    final rootPost = rootNode['post'];
    if (rootPost is Map<String, dynamic>) {
      rootUri = (rootPost['uri'] as String?) ?? uri;
      rootCid = (rootPost['cid'] as String?) ?? '';
    }

    final List<FeedItem> items = [];
    void collect(Map<String, dynamic> n) {
      final replies = n['replies'];
      if (replies is! List) return;
      for (final r in replies) {
        if (r is Map<String, dynamic>) {
          final post = r['post'];
          if (post is Map<String, dynamic>) {
            try {
              items.add(FeedItem.fromJson(post));
            } catch (_) {}
          }
          collect(r);
        }
      }
    }
    collect(thread);

    final List<FeedItem> ancestors = ancestorsRev.reversed.toList();
    return PostThreadData(
      rootUri: rootUri,
      rootCid: rootCid,
      ancestors: ancestors,
      replies: items,
    );
  }

  // Posting: reply
  Future<CreatedRecord> createReply({
    required String text,
    required String parentUri,
    required String parentCid,
    required String rootUri,
    required String rootCid,
    DateTime? createdAt,
    List<String>? langs,
  }) async {
    final now = (createdAt ?? DateTime.now().toUtc()).toIso8601String();
    final res = await _post('com.atproto.repo.createRecord', {
      'repo': _did,
      'collection': 'app.bsky.feed.post',
      'record': {
        r'$type': 'app.bsky.feed.post',
        'text': text,
        'createdAt': now,
        if (langs != null) 'langs': langs,
        'reply': {
          'root': {'uri': rootUri, 'cid': rootCid},
          'parent': {'uri': parentUri, 'cid': parentCid},
        },
      },
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return CreatedRecord.fromJson(map);
  }

  // Posting
  Future<CreatedRecord> createPost({
    required String text,
    DateTime? createdAt,
    List<String>? langs,
    Map<String, dynamic>? embed,
  }) async {
    final now = (createdAt ?? DateTime.now().toUtc()).toIso8601String();
    final res = await _post('com.atproto.repo.createRecord', {
      'repo': _did,
      'collection': 'app.bsky.feed.post',
      'record': {
        r'$type': 'app.bsky.feed.post', // Optional
        'text': text,
        'createdAt': now,
        if (langs != null) 'langs': langs,
        if (embed != null) 'embed': embed,
      },
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return CreatedRecord.fromJson(map);
  }

  // Upload image/file blob
  Future<Map<String, dynamic>> uploadBlob({
    required List<int> bytes,
    required String contentType,
  }) async {
    final res = await _client.post(
      _xrpc('com.atproto.repo.uploadBlob'),
      headers: {
        ..._headers(auth: true),
        'Content-Type': contentType,
      },
      body: bytes,
    );
    _throwIfError(res);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final blob = map['blob'];
    if (blob is Map<String, dynamic>) return blob;
    throw StateError('Invalid blob response');
  }

  // Likes
  Future<CreatedRecord> like({required String subjectUri, required String subjectCid}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final res = await _post('com.atproto.repo.createRecord', {
      'repo': _did,
      'collection': 'app.bsky.feed.like',
      'record': {
        r'$type': 'app.bsky.feed.like',
        'subject': {'uri': subjectUri, 'cid': subjectCid},
        'createdAt': now,
      },
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return CreatedRecord.fromJson(map);
  }

  Future<void> unlike({required String likeUri}) async {
    final rkey = _rkeyFromAtUri(likeUri);
    await _post('com.atproto.repo.deleteRecord', {
      'repo': _did,
      'collection': 'app.bsky.feed.like',
      'rkey': rkey,
    }, auth: true);
  }

  // Reposts
  Future<CreatedRecord> repost({required String subjectUri, required String subjectCid}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final res = await _post('com.atproto.repo.createRecord', {
      'repo': _did,
      'collection': 'app.bsky.feed.repost',
      'record': {
        r'$type': 'app.bsky.feed.repost',
        'subject': {'uri': subjectUri, 'cid': subjectCid},
        'createdAt': now,
      },
    }, auth: true);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return CreatedRecord.fromJson(map);
  }

  Future<void> unrepost({required String repostUri}) async {
    final rkey = _rkeyFromAtUri(repostUri);
    await _post('com.atproto.repo.deleteRecord', {
      'repo': _did,
      'collection': 'app.bsky.feed.repost',
      'rkey': rkey,
    }, auth: true);
  }

  static String _rkeyFromAtUri(String uri) {
    // at://did:plc:xyz/app.bsky.feed.like/3kfs... -> rkey is last segment
    final idx = uri.lastIndexOf('/');
    if (idx == -1 || idx == uri.length - 1) {
      throw ArgumentError('Invalid AT URI: $uri');
    }
    return uri.substring(idx + 1);
  }
}

class BskyHttpException implements Exception {
  final int statusCode;
  final String body;
  final String? reason;
  final String? code;
  final String? serverMessage;

  BskyHttpException({
    required this.statusCode,
    required this.body,
    this.reason,
    this.code,
    this.serverMessage,
  });

  @override
  String toString() {
    if (code != null || serverMessage != null) {
      final c = code ?? 'Error';
      final msg = serverMessage ?? '';
      return '$c: $msg';
    }
    return 'HTTP $statusCode${reason != null ? ' $reason' : ''}';
  }
}
