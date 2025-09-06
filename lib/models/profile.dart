class ActorProfile {
  final String did;
  final String handle;
  final String? displayName;
  final String? avatar;
  final String? banner;
  final String? description;
  final int followersCount;
  final int followsCount;
  final int postsCount;

  const ActorProfile({
    required this.did,
    required this.handle,
    this.displayName,
    this.avatar,
    this.banner,
    this.description,
    required this.followersCount,
    required this.followsCount,
    required this.postsCount,
  });

  factory ActorProfile.fromJson(Map<String, dynamic> json) => ActorProfile(
        did: json['did'] as String? ?? '',
        handle: json['handle'] as String? ?? '',
        displayName: json['displayName'] as String?,
        avatar: json['avatar'] as String?,
        banner: json['banner'] as String?,
        description: json['description'] as String?,
        followersCount: (json['followersCount'] as int?) ?? 0,
        followsCount: (json['followsCount'] as int?) ?? 0,
        postsCount: (json['postsCount'] as int?) ?? 0,
      );
}

class ActorListResponse {
  final String? cursor;
  final List<ActorProfile> items;
  const ActorListResponse({required this.cursor, required this.items});
}
