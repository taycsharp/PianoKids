import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:happy_piano_kids/screens/two_octave_piano_screen.dart';
import 'package:happy_piano_kids/services/audio_service.dart';
import 'package:happy_piano_kids/widgets/two_octave_keyboard.dart';

void main() {
  Future<void> setLandscapeSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> setPortraitSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('two octave keyboard exposes unique C4 keys and octave keys', (tester) async {
    await setLandscapeSize(tester);
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

  testWidgets('two octave screen shows mode buttons and demo panel in landscape', (tester) async {
    await setLandscapeSize(tester);
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: TwoOctavePianoScreen()),
      ),
    );

    expect(find.text('Free Play'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('piano-key-C3')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('piano-key-C5')), findsOneWidget);

    await tester.tap(find.text('Demo'));
    await tester.pump();

    expect(find.textContaining('Demo Playing'), findsOneWidget);
    expect(find.textContaining('/'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump();
  });

  testWidgets('two octave screen shows rotate prompt in portrait', (tester) async {
    await setPortraitSize(tester);
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: TwoOctavePianoScreen()),
      ),
    );

    expect(find.text('Rotate your iPhone'), findsOneWidget);
    expect(find.textContaining('Two Octave Piano works best in landscape'), findsOneWidget);
    expect(find.text('Free Play'), findsNothing);
    expect(find.text('Demo'), findsNothing);
    expect(find.text('Practice'), findsNothing);
  });

  testWidgets('song selector exposes multiple songs and updates selected song', (tester) async {
    await setLandscapeSize(tester);
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: TwoOctavePianoScreen()),
      ),
    );

    expect(find.byKey(const ValueKey<String>('demo-song-selector')), findsOneWidget);
    expect(find.text('Twinkle Twinkle'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('demo-song-selector')));
    await tester.pumpAndSettle();

    expect(find.text('Mary Had a Little Lamb'), findsWidgets);
    expect(find.text('Ode to Joy'), findsWidgets);
    expect(find.text('Hot Cross Buns'), findsWidgets);
    expect(find.text('Jingle Bells'), findsWidgets);
    expect(find.text('London Bridge'), findsWidgets);
    expect(find.text('Row Row Row Your Boat'), findsWidgets);
    expect(find.text('Happy Birthday Simple'), findsWidgets);

    await tester.tap(find.text('Mary Had a Little Lamb').last);
    await tester.pumpAndSettle();
    expect(find.text('Mary Had a Little Lamb'), findsOneWidget);

    await tester.tap(find.text('Demo'));
    await tester.pump();
    expect(find.textContaining('Demo Playing'), findsOneWidget);
  });

  
  testWidgets('selecting Happy Birthday Simple updates practice song', (tester) async {
    await setLandscapeSize(tester);
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: TwoOctavePianoScreen()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('demo-song-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Happy Birthday Simple').last);
    await tester.pumpAndSettle();

    expect(find.text('Happy Birthday Simple'), findsOneWidget);

    await tester.tap(find.text('Practice'));
    await tester.pump();

    expect(find.text('Practice: Happy Birthday Simple'), findsOneWidget);
    expect(find.textContaining('Note 1 /'), findsOneWidget);
  });
testWidgets('practice mode shows panel and progresses only on correct notes', (tester) async {
    await setLandscapeSize(tester);
    await tester.pumpWidget(
      Provider<AudioService>(
        create: (_) => AudioService(),
        child: const MaterialApp(home: TwoOctavePianoScreen()),
      ),
    );

    await tester.tap(find.text('Practice'));
    await tester.pump();

    expect(find.text('Practice: Twinkle Twinkle'), findsOneWidget);
    expect(find.text('Tap the glowing key'), findsOneWidget);
    expect(find.textContaining('Note 1 /'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('piano-key-D4')));
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Note 1 /'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('piano-key-C4-upper')));
    await tester.pump();
    expect(find.text('Great!'), findsOneWidget);
    expect(find.textContaining('Note 2 /'), findsOneWidget);
  });
}
