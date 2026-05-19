import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_piano_kids/widgets/two_octave_keyboard.dart';

void main() {
  testWidgets('two octave keyboard exposes unique C4 keys and octave keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 500,
            child: TwoOctaveKeyboard(
              onKeyPressStarted: (_, __) {},
              onKeyPressStopped: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('piano-key-C3')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('piano-key-E3')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('piano-key-C4-lower')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('piano-key-C4-upper')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('piano-key-E4')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('piano-key-C5')), findsOneWidget);
  });
}
