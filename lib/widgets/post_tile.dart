import 'package:flutter/material.dart';

import '../models/feed.dart';

class PostTile extends StatelessWidget {
  final FeedItem item;
  final VoidCallback? onLike;
  final VoidCallback? onMore;
  final VoidCallback? onAvatarTap;

  const PostTile({
    super.key,
    required this.item,
    this.onLike,
    this.onMore,
    this.onAvatarTap,
  });

  String _relativeTime(DateTime dt) {
    final d = DateTime.now().toUtc().difference(dt.toUtc());
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final ts = _relativeTime(item.createdAt);
    final name = item.authorDisplayName?.isNotEmpty == true
        ? item.authorDisplayName!
        : '@${item.authorHandle}';

    return InkWell(
      onTap: onMore,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onAvatarTap,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: item.authorAvatar != null && item.authorAvatar!.isNotEmpty
                    ? NetworkImage(item.authorAvatar!)
                    : null,
                child: (item.authorAvatar == null || item.authorAvatar!.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '@${item.authorHandle}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(ts, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
