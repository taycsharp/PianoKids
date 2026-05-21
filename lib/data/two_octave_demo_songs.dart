import 'package:flutter/foundation.dart';

@immutable
class DemoNoteEvent {
  final String note;
  final DemoHand hand;
  final Duration duration;

  const DemoNoteEvent({
    required this.note,
    required this.hand,
    required this.duration,
  });

  bool get isRightHand => hand == DemoHand.right;
}

enum DemoHand { left, right }

@immutable
class DemoSong {
  final String id;
  final String name;
  final List<DemoNoteEvent> events;

  const DemoSong({required this.id, required this.name, required this.events});
}

const List<DemoSong> twoOctaveDemoSongs = [
  DemoSong(id: 'twinkle_twinkle', name: 'Twinkle Twinkle', events: [
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'A4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'A4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
  ]),
  DemoSong(id: 'mary', name: 'Mary Had a Little Lamb', events: [
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
  ]),
  DemoSong(id: 'ode_to_joy', name: 'Ode to Joy', events: [
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 400)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
  ]),
  DemoSong(id: 'hot_cross_buns', name: 'Hot Cross Buns', events: [
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 600)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 600)),
  ]),
  DemoSong(id: 'jingle_bells', name: 'Jingle Bells', events: [
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 700)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
  ]),
  DemoSong(id: 'london_bridge', name: 'London Bridge', events: [
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'A4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 380)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 700)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
  ]),
  DemoSong(id: 'row_row_row', name: 'Row Row Row Your Boat', events: [
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 620)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 700)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
  ]),
  DemoSong(id: 'happy_birthday', name: 'Happy Birthday Simple', events: [
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 220)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'E4', hand: DemoHand.right, duration: Duration(milliseconds: 700)),
    DemoNoteEvent(note: 'C3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 320)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 220)),
    DemoNoteEvent(note: 'D4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'C4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'G4', hand: DemoHand.right, duration: Duration(milliseconds: 420)),
    DemoNoteEvent(note: 'F4', hand: DemoHand.right, duration: Duration(milliseconds: 700)),
    DemoNoteEvent(note: 'G3', hand: DemoHand.left, duration: Duration(milliseconds: 420)),
  ]),
];
