import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClassicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  final String? titleText; // if null, show Bluesky icon
  const ClassicAppBar({super.key, this.actions, this.leading, this.leadingWidth, this.titleText});

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
      title: titleText != null
          ? Text(
              titleText!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            )
          : ColorFiltered(
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

class ClassicCapsuleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const ClassicCapsuleButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x66FFFFFF))),
          backgroundColor: const Color(0x332196F3),
        ),
        child: Text(text, maxLines: 1, softWrap: false),
      ),
    );
  }
}

class ClassicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const ClassicIconButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0x55FFFFFF), Color(0x22000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
