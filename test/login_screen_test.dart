import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:crimsoncrisis/screens/login_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/session.dart';

class _SpySession extends SessionController {
  bool called = false;
  String? id;
  String? pw;
  String? pdsValue;

  @override
  Future<Session?> build() async => null;

  @override
  BskyApi? get api => BskyApi(pds: 'https://example.invalid');

  @override
  Future<void> login({
    required String identifier,
    required String password,
    String pds = 'https://bsky.social',
  }) async {
    called = true;
    id = identifier;
    pw = password;
    pdsValue = pds;
    state = const AsyncData(null);
  }
}

void main() {
  testWidgets('LoginScreen calls SessionController.login with default PDS', (tester) async {
    final spy = _SpySession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => spy)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Fill identifier and password (three TextFields exist: id, pw, pds)
    await tester.enterText(find.byType(TextField).at(0), 'alice');
    await tester.enterText(find.byType(TextField).at(1), 'xxxx-xxxx-xxxx-xxxx');

    // Tap login
    await tester.tap(find.text('ログイン'));
    await tester.pump();

    expect(spy.called, isTrue);
    expect(spy.id, 'alice');
    expect(spy.pw, 'xxxx-xxxx-xxxx-xxxx');
    expect(spy.pdsValue, 'https://bsky.social');
  });

  testWidgets('LoginScreen passes custom PDS when edited', (tester) async {
    final spy = _SpySession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => spy)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // id / pw / pds fields (index 2 is PDS)
    await tester.enterText(find.byType(TextField).at(0), 'bob');
    await tester.enterText(find.byType(TextField).at(1), 'yyyy-yyyy-yyyy-yyyy');
    await tester.enterText(find.byType(TextField).at(2), 'https://example.com');

    await tester.tap(find.text('ログイン'));
    await tester.pump();

    expect(spy.called, isTrue);
    expect(spy.id, 'bob');
    expect(spy.pw, 'yyyy-yyyy-yyyy-yyyy');
    expect(spy.pdsValue, 'https://example.com');
  });
}

