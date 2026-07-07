import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/main.dart';

void main() {
  testWidgets('Soundwave app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SoundwaveApp());
    expect(find.text('Soundwave'), findsOneWidget);
  });
}
