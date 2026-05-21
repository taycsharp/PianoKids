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

const _n = Duration(milliseconds: 420);
const _h = Duration(milliseconds: 640);

DemoNoteEvent _r(String note, [Duration duration = _n]) =>
    DemoNoteEvent(note: note, hand: DemoHand.right, duration: duration);
DemoNoteEvent _l(String note, [Duration duration = _n]) =>
    DemoNoteEvent(note: note, hand: DemoHand.left, duration: duration);

const List<DemoSong> twoOctaveDemoSongs = [
  DemoSong(id: 'twinkle_twinkle', name: 'Twinkle Twinkle', events: [
    _r('C4'), _r('C4'), _r('G4'), _r('G4'), _r('A4'), _r('A4'), _r('G4', _h), _l('C3'),
    _r('F4'), _r('F4'), _r('E4'), _r('E4'), _r('D4'), _r('D4'), _r('C4', _h), _l('F3'),
    _r('G4'), _r('G4'), _r('F4'), _r('F4'), _r('E4'), _r('E4'), _r('D4', _h), _l('G3'),
    _r('G4'), _r('G4'), _r('F4'), _r('F4'), _r('E4'), _r('E4'), _r('D4', _h), _l('G3'),
    _r('C4'), _r('C4'), _r('G4'), _r('G4'), _r('A4'), _r('A4'), _r('G4', _h), _l('C3'),
    _r('F4'), _r('F4'), _r('E4'), _r('E4'), _r('D4'), _r('D4'), _r('C4', _h), _l('C3'),
  ]),
  DemoSong(id: 'mary', name: 'Mary Had a Little Lamb', events: [
    _r('E4'), _r('D4'), _r('C4'), _r('D4'), _r('E4'), _r('E4'), _r('E4', _h), _l('C3'),
    _r('D4'), _r('D4'), _r('D4', _h), _r('E4'), _r('G4'), _r('G4', _h), _l('G3'),
    _r('E4'), _r('D4'), _r('C4'), _r('D4'), _r('E4'), _r('E4'), _r('E4', _h), _l('C3'),
    _r('E4'), _r('D4'), _r('D4'), _r('E4'), _r('D4'), _r('C4', _h), _l('F3'),
  ]),
  DemoSong(id: 'ode_to_joy', name: 'Ode to Joy', events: [
    _r('E4'), _r('E4'), _r('F4'), _r('G4'), _r('G4'), _r('F4'), _r('E4'), _r('D4'), _l('C3'),
    _r('C4'), _r('C4'), _r('D4'), _r('E4'), _r('E4'), _r('D4'), _r('D4', _h), _l('G3'),
    _r('E4'), _r('E4'), _r('F4'), _r('G4'), _r('G4'), _r('F4'), _r('E4'), _r('D4'), _l('C3'),
    _r('C4'), _r('C4'), _r('D4'), _r('E4'), _r('D4'), _r('C4'), _r('C4', _h), _l('C3'),
  ]),
  DemoSong(id: 'hot_cross_buns', name: 'Hot Cross Buns', events: [
    _r('E4'), _r('D4'), _r('C4', _h), _l('C3'),
    _r('E4'), _r('D4'), _r('C4', _h), _l('C3'),
    _r('C4'), _r('C4'), _r('C4'), _r('C4'), _r('D4'), _r('D4'), _r('D4'), _r('D4'), _l('G3'),
    _r('E4'), _r('D4'), _r('C4', _h), _l('C3'),
  ]),
  DemoSong(id: 'jingle_bells', name: 'Jingle Bells', events: [
    _r('E4'), _r('E4'), _r('E4', _h), _l('C3'),
    _r('E4'), _r('E4'), _r('E4', _h), _l('C3'),
    _r('E4'), _r('G4'), _r('C4'), _r('D4'), _r('E4', _h), _l('G3'),
    _r('F4'), _r('F4'), _r('F4'), _r('F4'), _r('F4'), _r('E4'), _r('E4'), _r('E4'), _l('F3'),
    _r('E4'), _r('D4'), _r('D4'), _r('E4'), _r('D4'), _r('G4', _h), _l('G3'),
  ]),
  DemoSong(id: 'london_bridge', name: 'London Bridge', events: [
    _r('G4'), _r('A4'), _r('G4'), _r('F4'), _r('E4'), _r('F4'), _r('G4', _h), _l('C3'),
    _r('D4'), _r('E4'), _r('F4', _h), _l('F3'),
    _r('E4'), _r('F4'), _r('G4', _h), _l('G3'),
    _r('G4'), _r('A4'), _r('G4'), _r('F4'), _r('E4'), _r('F4'), _r('G4', _h), _l('C3'),
    _r('D4'), _r('G4'), _r('E4'), _r('C4', _h), _l('C3'),
  ]),
  DemoSong(id: 'row_row_row', name: 'Row Row Row Your Boat', events: [
    _r('C4'), _r('C4'), _r('C4'), _r('D4'), _r('E4', _h), _l('C3'),
    _r('E4'), _r('D4'), _r('E4'), _r('F4'), _r('G4', _h), _l('G3'),
    _r('C5'), _r('C5'), _r('C5'), _r('G4'), _r('G4'), _r('G4'), _l('C3'),
    _r('E4'), _r('E4'), _r('E4'), _r('C4'), _r('C4'), _r('C4'), _l('F3'),
    _r('G4'), _r('F4'), _r('E4'), _r('D4'), _r('C4', _h), _l('C3'),
  ]),
  DemoSong(id: 'happy_birthday', name: 'Happy Birthday Simple', events: [
    _r('C4'), _r('C4'), _r('D4'), _r('C4'), _r('F4'), _r('E4', _h), _l('C3'),
    _r('C4'), _r('C4'), _r('D4'), _r('C4'), _r('G4'), _r('F4', _h), _l('G3'),
    _r('C4'), _r('C4'), _r('C5'), _r('A4'), _r('F4'), _r('E4'), _r('D4', _h), _l('F3'),
    _r('A4'), _r('A4'), _r('F4'), _r('G4'), _r('F4', _h), _l('C3'),
  ]),
];
