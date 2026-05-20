import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:happy_piano_kids/app.dart';
import 'package:happy_piano_kids/providers/progress_provider.dart';
import 'package:happy_piano_kids/screens/ear_training_screen.dart';
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

  testWidgets('piano key pointers start and stop independently', (tester) async {
    final started = <String>[];
    final stopped = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              child: PianoKeyboard(
                onKeyPressStarted: (note, _) => started.add(note),
                onKeyPressStopped: (note, _) => stopped.add(note),
              ),
            ),
          ),
        ),
      ),
    );

    final cGesture = await tester.startGesture(tester.getCenter(find.text('C').first));
    await tester.pump();
    final eGesture = await tester.startGesture(tester.getCenter(find.text('E')));
    await tester.pump();

    expect(started, ['C', 'E']);
    expect(stopped, isEmpty);

    await cGesture.up();
    await tester.pump();

    expect(stopped, ['C']);

    await eGesture.up();
    await tester.pump();

    expect(stopped, ['C', 'E']);
  });

  testWidgets('piano keyboard remains tappable while audio readiness is false', (tester) async {
    final started = <String>[];
    final stopped = <String>[];
    final isKeyboardReady = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 720,
            child: ValueListenableBuilder<bool>(
              valueListenable: isKeyboardReady,
              builder: (context, ready, child) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: ready ? 1 : 0.55,
                  child: PianoKeyboard(
                    onKeyPressStarted: (note, _) => started.add(note),
                    onKeyPressStopped: (note, _) => stopped.add(note),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PianoKeyboard), findsOneWidget);
    await tester.tap(find.text('C').first);
    await tester.pumpAndSettle();

    expect(started, isNotEmpty);
    expect(stopped, isNotEmpty);
    isKeyboardReady.dispose();
  });

  testWidgets('ear training high-low mode shows play and answer controls', (tester) async {
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: EarTrainingScreen()),
      ),
    );

    expect(find.text('Play Sound'), findsOneWidget);
    expect(find.text('Low Sound'), findsOneWidget);
    expect(find.text('High Sound'), findsOneWidget);
  });

  testWidgets('ear training answer shows friendly feedback', (tester) async {
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: EarTrainingScreen()),
      ),
    );

    await tester.tap(find.text('Low Sound'));
    await tester.pump();

    expect(
      find.textContaining('Great listening!').evaluate().isNotEmpty ||
          find.textContaining('Good try! Listen again.').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
