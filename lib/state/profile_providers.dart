import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import 'auth_providers.dart';

final profileProvider = FutureProvider.family<ActorProfile, String>((ref, actor) async {
  final api = ref.read(sessionProvider.notifier).api;
  if (api == null) throw StateError('Not authenticated');
  return api.getProfile(actor: actor);
});

