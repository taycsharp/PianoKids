import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/song_data.dart';
import '../providers/progress_provider.dart';
import '../services/audio_service.dart';
import '../widgets/song_card.dart';
import 'song_practice_screen.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  @override
  void dispose() {
    context.read<AudioService>().stopAllNotes();
    super.dispose();
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
              for (final song in SongData.songs)
                SongCard(
                  song: song,
                  completed: progress.progress.completedSongIds.contains(song.id),
                  onDemo: isAudioReady
                      ? () => context.read<AudioService>().playSongDemo(song)
                      : null,
                  onStop: isAudioReady
                      ? () => context.read<AudioService>().stopAllNotes()
                      : null,
                  onPractice: isAudioReady
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SongPracticeScreen(song: song),
                            ),
                          )
                      : null,
                ),
            ],
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
