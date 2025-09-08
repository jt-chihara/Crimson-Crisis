import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_providers.dart';
import 'timeline_screen.dart';
import 'profile_screen.dart';
import 'connect_screen.dart';
import '../widgets/classic_bottom_bar.dart';
import '../widgets/tab_navigator.dart';

class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index;
  final _navKeys = <GlobalKey<NavigatorState>>[
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _onTabTap(int i) {
    if (i == _index) {
      final nav = _navKeys[i].currentState;
      nav?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final meActor = session?.did ?? '';

    final pages = <Widget>[
      TabNavigator(navigatorKey: _navKeys[0], root: const TimelineScreen()),
      TabNavigator(navigatorKey: _navKeys[1], root: const ConnectScreen()),
      const _PlaceholderScreen(title: 'Discover'),
      if (meActor.isNotEmpty)
        TabNavigator(
          navigatorKey: _navKeys[3],
          root: ProfileScreen(actor: meActor),
        )
      else
        const _PlaceholderScreen(title: 'Me'),
    ];

    return WillPopScope(
      onWillPop: () async {
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: ClassicBottomBar(
          currentIndex: _index,
          onTap: _onTabTap,
          items: const [
            ClassicBottomItem(icon: Icons.home, label: 'Home'),
            ClassicBottomItem(icon: Icons.alternate_email, label: 'Connect'),
            ClassicBottomItem(icon: Icons.tag, label: 'Discover'),
            ClassicBottomItem(icon: Icons.person, label: 'Me'),
          ],
        ),
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
