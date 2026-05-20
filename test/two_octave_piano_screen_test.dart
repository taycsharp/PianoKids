import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:happy_piano_kids/screens/two_octave_piano_screen.dart';
import 'package:happy_piano_kids/services/audio_service.dart';
import 'package:happy_piano_kids/widgets/two_octave_keyboard.dart';

void main() {
  testWidgets('two octave keyboard exposes unique C4 keys and octave keys', (tester) async {
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

  testWidgets('two octave screen shows mode buttons and demo panel', (tester) async {
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: TwoOctavePianoScreen()),
      ),
    );

    expect(find.text('Free Play'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);

    await tester.tap(find.text('Demo'));
    await tester.pump();

    expect(find.textContaining('Demo Playing'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
  });
}
