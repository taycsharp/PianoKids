import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/progress_provider.dart';
import '../services/audio_service.dart';
import '../services/content_repository.dart';
import '../widgets/song_card.dart';
import 'song_practice_screen.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  late final Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = context.read<ContentRepository>().getSongs();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final audio = context.read<AudioService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Songs')),
      body: ValueListenableBuilder<bool>(
        valueListenable: audio.keyboardCacheReadyListenable,
        builder: (context, isAudioReady, child) {
          return FutureBuilder<List<Song>>(
            future: _songsFuture,
            builder: (context, snapshot) {
              final songs = snapshot.data ?? const <Song>[];
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    'Choose a song!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (!isAudioReady) ...[
                    const SizedBox(height: 12),
                    const _LoadingPianoSoundsBanner(),
                  ],
                  const SizedBox(height: 14),
                  for (final song in songs)
                    SongCard(
                      song: song,
                      completed: progress.progress.completedSongIds.contains(song.id),
                      onDemo: () => context.read<AudioService>().playSongDemo(song),
                      onPractice: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SongPracticeScreen(song: song),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadingPianoSoundsBanner extends StatelessWidget {
  const _LoadingPianoSoundsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3B0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading piano sounds…',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
