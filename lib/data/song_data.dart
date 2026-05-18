import '../models/song.dart';

class SongData {
  static const songs = <Song>[
    Song(
      id: 'mary_lamb',
      title: 'Mary Had a Little Lamb',
      difficulty: 'Easy',
      description: 'A gentle song using C, D, E, and G.',
      notes: ['E', 'D', 'C', 'D', 'E', 'E', 'E', 'D', 'D', 'D', 'E', 'G', 'G'],
    ),
    Song(
      id: 'twinkle',
      title: 'Twinkle Twinkle Little Star',
      difficulty: 'Easy',
      description: 'A famous star song for beginners.',
      notes: ['C', 'C', 'G', 'G', 'A', 'A', 'G', 'F', 'F', 'E', 'E', 'D', 'D', 'C'],
    ),
    Song(
      id: 'hot_cross_buns',
      title: 'Hot Cross Buns',
      difficulty: 'Very Easy',
      description: 'A short song with three notes.',
      notes: ['E', 'D', 'C', 'E', 'D', 'C', 'C', 'C', 'C', 'C', 'D', 'D', 'D', 'D', 'E', 'D', 'C'],
    ),
    Song(
      id: 'ode_to_joy',
      title: 'Ode to Joy',
      difficulty: 'Easy+',
      description: 'A simple beginner version.',
      notes: ['E', 'E', 'F', 'G', 'G', 'F', 'E', 'D', 'C', 'C', 'D', 'E', 'E', 'D', 'D'],
    ),
  ];
}
