import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/screens/compose_screen.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ComposeApi extends BskyApi {
  _ComposeApi() : super(pds: 'https://example.com');
  String? lastText;
  @override
  Future<CreatedRecord> createPost({required String text, DateTime? createdAt, List<String>? langs, Map<String, dynamic>? embed}) async {
    lastText = text;
    return CreatedRecord(uri: 'u', cid: 'c');
  }
}

class _ComposeSession extends SessionController {
  final _ComposeApi apiImpl;
  _ComposeSession(this.apiImpl);

  @override
  BskyApi? get api => apiImpl;

  @override
  Future<Session?> build() async => const Session(
        did: 'did:me',
        handle: 'me',
        accessJwt: 'a',
        refreshJwt: 'r',
        pds: 'https://example.com',
      );
}

void main() {
  testWidgets('ComposeScreen posts when send is tapped', (tester) async {
    final api = _ComposeApi();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _ComposeSession(api))],
        child: const MaterialApp(home: ComposeScreen()),
      ),
    );

    // enter text
    await tester.enterText(find.byType(TextField).first, 'hello world');
    await tester.pump();

    // tap send
    await tester.tap(find.widgetWithText(TextButton, '送信'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(api.lastText, 'hello world');
  });
}
