import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/bsky_api.dart';
import '../core/session_storage.dart';
import '../models/session.dart';

final bskyApiProvider = Provider<BskyApi>((ref) {
  // Default API; may be overwritten after login based on session.pds
  return BskyApi();
});

final sessionProvider = AsyncNotifierProvider<SessionController, Session?>(
  SessionController.new,
);

class SessionController extends AsyncNotifier<Session?> {
  late SessionStorage _storage;
  BskyApi? _api;

  @override
  Future<Session?> build() async {
    _storage = SessionStorage();
    final saved = await _storage.load();
    if (saved != null) {
      _api = BskyApi(pds: saved.pds)
        ..setTokens(saved.accessJwt, saved.refreshJwt, saved.did);
      // Override the provider so other readers get the configured API
      ref.onDispose(() {});
      // No-op; in widgets where needed, use apiFromSession
    }
    return saved;
  }

  BskyApi _ensureApi(String pds) {
    _api ??= BskyApi(pds: pds);
    return _api!;
  }

  Future<void> login({
    required String identifier,
    required String password,
    String pds = 'https://bsky.social',
  }) async {
    state = const AsyncLoading();
    try {
      final api = _ensureApi(pds);
      final ses = await api.createSession(identifier: identifier, password: password);
      await _storage.save(ses);
      state = AsyncData(ses);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AsyncData(null);
  }

  BskyApi? get api => _api;
}

