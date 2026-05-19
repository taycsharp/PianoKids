import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:happy_piano_kids/app.dart';
import 'package:happy_piano_kids/providers/progress_provider.dart';
import 'package:happy_piano_kids/services/audio_service.dart';
import 'package:happy_piano_kids/services/progress_service.dart';
import 'package:happy_piano_kids/widgets/piano_keyboard.dart';

void main() {
  testWidgets('Happy Piano Kids app starts', (WidgetTester tester) async {
    final progressProvider = ProgressProvider(ProgressService());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AudioService>(create: (_) => AudioService()),
          ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
        ],
        child: const HappyPianoKidsApp(),
      ),
    );

    expect(find.text('Happy Piano Kids'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.text('Start Learning'), findsOneWidget);
  });

  testWidgets('two-row keyboard duplicate C4 keys both trigger C4 note', (tester) async {
    final started = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: PianoKeyboard(
              twoRowLayout: true,
              onKeyPressStarted: (note, _) => started.add(note),
            ),
          ),
        ),
      ),
    );

    final lower = find.bySemanticsLabel('piano-key-C4-lower');
    final upper = find.bySemanticsLabel('piano-key-C4-upper');
    expect(lower, findsOneWidget);
    expect(upper, findsOneWidget);

    await tester.tap(lower);
    await tester.pump();
    await tester.tap(upper);
    await tester.pump();

    expect(started, ['C4', 'C4']);
    expect(find.bySemanticsLabel('piano-key-E4'), findsOneWidget);
  });
}
