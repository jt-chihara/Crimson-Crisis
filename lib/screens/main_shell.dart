import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';
import 'timeline_screen.dart';
import 'profile_screen.dart';
import '../widgets/classic_bottom_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final meActor = session?.did ?? '';

    final pages = <Widget>[
      const TimelineScreen(),
      const _PlaceholderScreen(title: 'Connect'),
      const _PlaceholderScreen(title: 'Discover'),
      if (meActor.isNotEmpty) ProfileScreen(actor: meActor) else const _PlaceholderScreen(title: 'Me'),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: ClassicBottomBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          ClassicBottomItem(icon: Icons.home, label: 'Home'),
          ClassicBottomItem(icon: Icons.alternate_email, label: 'Connect'),
          ClassicBottomItem(icon: Icons.tag, label: 'Discover'),
          ClassicBottomItem(icon: Icons.person, label: 'Me'),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title coming soon'),
      ),
    );
  }
}
