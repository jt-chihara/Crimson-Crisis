class Session {
  final String did;
  final String handle;
  final String accessJwt;
  final String refreshJwt;
  final String pds;

  const Session({
    required this.did,
    required this.handle,
    required this.accessJwt,
    required this.refreshJwt,
    required this.pds,
  });

  Map<String, Object?> toJson() => {
        'did': did,
        'handle': handle,
        'accessJwt': accessJwt,
        'refreshJwt': refreshJwt,
        'pds': pds,
      };

  factory Session.fromJson(Map<String, Object?> json) => Session(
        did: json['did'] as String,
        handle: json['handle'] as String,
        accessJwt: json['accessJwt'] as String,
        refreshJwt: json['refreshJwt'] as String,
        pds: json['pds'] as String,
      );
}

