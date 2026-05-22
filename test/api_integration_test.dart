import 'package:flutter_test/flutter_test.dart';
import 'package:happy_piano_kids/models/lesson.dart';
import 'package:happy_piano_kids/models/remote_models.dart';
import 'package:happy_piano_kids/services/api_client.dart';
import 'package:happy_piano_kids/services/content_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.throwOnSongs = false, this.throwOnTwoOctaveSongs = false});

  final bool throwOnSongs;
  final bool throwOnTwoOctaveSongs;

  @override
  Future<Map<String, dynamic>> getSongs() async {
    if (throwOnSongs) throw ApiException('failed');
    return const {'data': []};
  }

  @override
  Future<Map<String, dynamic>> getLessons() async => const {'data': []};

  @override
  Future<Map<String, dynamic>> getTwoOctaveSongs() async {
    if (throwOnTwoOctaveSongs) throw ApiException('failed');
    return const {'data': []};
  }
}

void main() {
  test('successful remote song parsing', () {
    final songs = RemoteMappers.mapSongs({
      'data': [
        {
          'id': 'remote_1',
          'title': 'Remote Song',
          'difficulty': 'Easy',
          'tempo_bpm': 120,
          'description': 'From API',
          'steps': [
            {'note': 'C', 'beats': 1},
            {'note': null, 'beats': 0.5},
          ],
        }
      ]
    });

    expect(songs, hasLength(1));
    expect(songs.first.id, 'remote_1');
    expect(songs.first.steps[1].isRest, isTrue);
  });

  test('successful remote lesson parsing', () {
    final lessons = RemoteMappers.mapLessons({
      'data': [
        {
          'id': 'lesson_remote',
          'title': 'Remote Lesson',
          'description': 'API lesson',
          'icon': '🎵',
          'required_notes': ['C', 'D'],
          'task_type': 'song',
        }
      ]
    });

    expect(lessons, hasLength(1));
    expect(lessons.first.id, 'lesson_remote');
    expect(lessons.first.taskType, LessonTaskType.song);
  });

  test('API failure fallback to local data', () async {
    final repository = ContentRepository(apiClient: _FakeApiClient(throwOnSongs: true));
    final songs = await repository.getSongs();

    expect(songs, isNotEmpty);
    expect(songs.first.id, 'mary_lamb');
  });

  test('two octave local fallback excludes London Bridge', () async {
    final repository = ContentRepository(apiClient: _FakeApiClient(throwOnTwoOctaveSongs: true));
    final songs = await repository.getTwoOctaveSongs();

    expect(songs.map((song) => song.name), isNot(contains('London Bridge')));
    expect(songs.map((song) => song.name), contains('Happy Birthday Simple'));
  });
}
