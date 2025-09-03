import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final dt = item.createdAt;
    final ts = DateFormat('y/MM/dd HH:mm').format(dt.toLocal());
    return ListTile(
      leading: InkWell(
        onTap: onAvatarTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          backgroundImage: item.authorAvatar != null && item.authorAvatar!.isNotEmpty
              ? NetworkImage(item.authorAvatar!)
              : null,
          child: (item.authorAvatar == null || item.authorAvatar!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
      ),
      title: Text(
        item.authorDisplayName?.isNotEmpty == true
            ? '${item.authorDisplayName} (@${item.authorHandle})'
            : '@${item.authorHandle}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.text),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(ts, style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              IconButton(
                onPressed: onLike,
                icon: Icon(
                  Icons.favorite,
                  color: item.viewerLike != null ? Colors.pink : Colors.grey,
                ),
              ),
              Text('${item.likeCount}'),
              const SizedBox(width: 12),
              const Icon(Icons.repeat, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${item.repostCount}'),
            ],
          ),
        ],
      ),
      onTap: onMore,
      isThreeLine: true,
    );
  }
}
