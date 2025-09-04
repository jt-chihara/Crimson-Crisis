import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClassicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  const ClassicAppBar({super.key, this.actions, this.leading, this.leadingWidth});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2E7CC1),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: leading,
      leadingWidth: leadingWidth,
      actions: actions,
      title: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: Image.network(
          'https://bsky.app/static/apple-touch-icon.png',
          height: 24,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud, color: Colors.white),
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A6DA9), Color(0xFF56A8E7)],
          ),
        ),
      ),
    );
  }
}
