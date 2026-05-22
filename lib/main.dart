import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/progress_provider.dart';
import 'services/audio_service.dart';
import 'services/content_repository.dart';
import 'services/progress_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final progressService = ProgressService();
  final progressProvider = ProgressProvider(progressService);
  await progressProvider.loadProgress();

  runApp(
    MultiProvider(
      providers: [
        Provider<AudioService>(create: (_) => AudioService()),
        ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
        Provider<ContentRepository>(create: (_) => ContentRepository()),
      ],
      child: const HappyPianoKidsApp(),
    ),
  );
}
