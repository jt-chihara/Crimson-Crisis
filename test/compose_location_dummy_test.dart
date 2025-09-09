import 'package:crimsoncrisis/api/bsky_api.dart';
import 'package:crimsoncrisis/models/feed.dart';
import 'package:crimsoncrisis/models/session.dart';
import 'package:crimsoncrisis/widgets/compose_sheet.dart';
import 'package:crimsoncrisis/state/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ComposeApi extends BskyApi {
  _ComposeApi() : super(pds: 'https://example.com');
  @override
  Future<CreatedRecord> createPost({required String text, DateTime? createdAt, List<String>? langs, Map<String, dynamic>? embed}) async {
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
  testWidgets('tapping location shows dummy dialog', (tester) async {
    BuildContext? ctx;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _ComposeSession(_ComposeApi()))],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    // Do not await; the Future completes when the sheet is closed.
    showComposeSheet(ctx!);
    await tester.pumpAndSettle();

    await tester.tap(find.text('位置情報を追加'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('blueskyは位置情報を追加できません'), findsOneWidget);

    // Close dialog and then the compose sheet
    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
  });
}
