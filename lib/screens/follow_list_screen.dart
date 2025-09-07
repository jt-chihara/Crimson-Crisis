import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/classic_app_bar.dart';
import '../state/auth_providers.dart';
import '../api/bsky_api.dart';
import '../models/profile.dart';
import 'profile_screen.dart';
import '../widgets/classic_bottom_bar.dart';
import 'main_shell.dart';

class FollowListScreen extends ConsumerStatefulWidget {
  final String actor; // did or handle
  final bool showFollowing; // true: following list, false: followers list
  const FollowListScreen({super.key, required this.actor, required this.showFollowing});

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  final _items = <ActorProfile>[];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;

  BskyApi get _api => ref.read(sessionProvider.notifier).api!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = widget.showFollowing
          ? await _api.getFollows(actor: widget.actor, limit: 50)
          : await _api.getFollowers(actor: widget.actor, limit: 50);
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _cursor = res.cursor;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = widget.showFollowing
          ? await _api.getFollows(actor: widget.actor, cursor: _cursor, limit: 50)
          : await _api.getFollowers(actor: widget.actor, cursor: _cursor, limit: 50);
      setState(() {
        _items.addAll(res.items);
        _cursor = res.cursor;
      });
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: ClassicAppBar(
        leadingWidth: 72,
        leading: Tooltip(
          message: '戻る',
          child: ClassicIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        actions: const [
          ClassicIconButton(icon: Icons.edit),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _items.length + 1,
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    if (_cursor != null) {
                      _loadMore();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox(height: 80);
                  }
                  final u = _items[index];
                  return _UserTile(
                    profile: u,
                    onTap: () {
                      final actor = u.did.isNotEmpty ? u.did : u.handle;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProfileScreen(actor: actor)),
                      );
                    },
                  );
                },
              ),
            ),
      bottomNavigationBar: ClassicBottomBar(
        currentIndex: _currentTabIndex(ref),
        onTap: (i) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainShell(initialIndex: i)),
            (route) => false,
          );
        },
        items: const [
          ClassicBottomItem(icon: Icons.home, label: 'Home'),
          ClassicBottomItem(icon: Icons.alternate_email, label: 'Connect'),
          ClassicBottomItem(icon: Icons.tag, label: 'Discover'),
          ClassicBottomItem(icon: Icons.person, label: 'Me'),
        ],
      ),
    );
  }

  int _currentTabIndex(WidgetRef ref) {
    final ses = ref.watch(sessionProvider).valueOrNull;
    final isMe = ses != null && (widget.actor == ses.did || widget.actor == ses.handle);
    return isMe ? 3 : 0; // Me tab when viewing own lists
  }
}

class _UserTile extends StatelessWidget {
  final ActorProfile profile;
  final VoidCallback onTap;
  const _UserTile({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (profile.avatar != null && profile.avatar!.isNotEmpty)
                  ? NetworkImage(profile.avatar!)
                  : null,
              child: (profile.avatar == null || profile.avatar!.isEmpty) ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName ?? '@${profile.handle}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('@${profile.handle}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
