import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/feed_providers.dart';
import '../widgets/post_tile.dart';
import '../widgets/classic_app_bar.dart';
import '../widgets/compose_sheet.dart';
import 'profile_screen.dart';
import 'post_detail_screen.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(timelineProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: ClassicAppBar(
        actions: [
          Tooltip(
            message: '投稿',
            child: ClassicIconButton(
              icon: Icons.edit,
              onPressed: () async {
                final ok = await showComposeSheet(context);
                if (ok == true) {
                  await ref.read(timelineProvider.notifier).refresh();
                }
              },
            ),
          ),
        ],
      ),
      body: timeline.when(
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(timelineProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: data.items.length + 1,
            itemBuilder: (context, index) {
              if (index == data.items.length) {
                // Load more trigger and indicator
                if (data.cursor != null) {
                  ref.read(timelineProvider.notifier).loadMore();
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  return const SizedBox(height: 80);
                }
              }
              final item = data.items[index];
              return PostTile(
                item: item,
                onLike: () => ref.read(timelineProvider.notifier).toggleLike(item),
                onMore: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(item: item),
                    ),
                  );
                },
                onAvatarTap: () {
                  final actor = item.authorDid.isNotEmpty
                      ? item.authorDid
                      : (item.authorHandle.isNotEmpty ? item.authorHandle : '');
                  if (actor.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(actor: actor),
                    ),
                  );
                },
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('読み込みに失敗: $e'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.read(timelineProvider.notifier).refresh(),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
