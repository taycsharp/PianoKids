import '../data/lesson_data.dart';
import '../data/song_data.dart';
import '../data/two_octave_demo_songs.dart';
import '../models/lesson.dart';
import '../models/remote_models.dart';
import '../models/song.dart';
import 'api_client.dart';

class ContentRepository {
  ContentRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Song>> getSongs() async {
    try {
      final json = await _apiClient.getSongs();
      final songs = RemoteMappers.mapSongs(json);
      if (songs.isEmpty) return SongData.songs;
      return songs;
    } catch (_) {
      return SongData.songs;
    }
  }

  Future<List<Lesson>> getLessons() async {
    try {
      final json = await _apiClient.getLessons();
      final lessons = RemoteMappers.mapLessons(json);
      if (lessons.isEmpty) return LessonData.lessons;
      return lessons;
    } catch (_) {
      return LessonData.lessons;
    }
  }

  Future<List<DemoSong>> getTwoOctaveSongs() async {
    try {
      final json = await _apiClient.getTwoOctaveSongs();
      final songs = RemoteMappers.mapTwoOctaveSongs(json);
      if (songs.isEmpty) return twoOctaveDemoSongs;
      return songs;
    } catch (_) {
      return twoOctaveDemoSongs;
    }
  }
}
