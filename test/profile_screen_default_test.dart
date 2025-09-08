import 'package:flutter_test/flutter_test.dart';
import 'package:crimsoncrisis/screens/profile_screen.dart';

void main() {
  test('ProfileScreen.showBottomBar defaults to false', () {
    const screen = ProfileScreen(actor: 'did:example:alice');
    expect(screen.showBottomBar, isFalse);
  });
}

