import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../models/song.dart';

/// Audio service for Happy Piano Kids.
///
/// Audio strategy:
/// 1. Generate warm synthetic piano WAV tones in memory.
/// 2. Use SoLoud memory playback for low-latency notes when available.
/// 3. If SoLoud memory notes are not ready, play generated one-shot WAV notes.
/// 4. If audio fails, skip safely so the child can continue using the app.
///
/// Important: the generated tone is not a copyrighted sample or exact clone of
/// Steinway, Yamaha, or any other brand. It is a brand-inspired, synthetic,
/// wood-piano-like tone designed for a kid-friendly MVP.
class AudioService {
  AudioService() {
    keyboardCacheReady = _initializeKeyboardAudio();
    unawaited(keyboardCacheReady);
  }

  final AudioPlayer _effectsPlayer = AudioPlayer();
  final SoLoud _soloud = SoLoud.instance;
  final Map<String, AudioSource> _keyboardSoundByNote = {};
  final Map<String, AudioSource> _keyboardAttackSoundByNote = {};
  final Map<String, AudioSource> _keyboardSustainSoundByNote = {};
  final Map<String, _KeyboardSampleInfo> _keyboardSampleInfoByNote = {};
  final Map<int, ActiveKeyboardVoice> _activeKeyboardVoicesByPressId = {};
  final ValueNotifier<bool> _keyboardCacheReadyNotifier = ValueNotifier(false);
  late final Future<void> keyboardCacheReady;
  var _songDemoToken = 0;
  var _isSoLoudReady = false;

  bool get isKeyboardCacheReady => _isSoLoudReady;

  ValueListenable<bool> get keyboardCacheReadyListenable =>
      _keyboardCacheReadyNotifier;

  static const double _demoTempoMultiplier = 1.0;
  static const int _songGapMs = 45;
  static const int _keyboardNoteDurationMs = 1200;
  static const int _keyboardAttackDurationMs = 180;
  static const int _keyboardSustainDurationMs = 3600;
  static const Duration _keyboardReleaseFadeDuration = Duration(
    milliseconds: 180,
  );
  static const bool _keyboardDebugLogs = false;
  static const bool _useDiagnosticClickTone = false;
  static const Duration _audioStartTimeout = Duration(milliseconds: 900);

  static const int _sampleRate = 44100;
  static const int _channels = 2;
  static const int _bitsPerSample = 16;

  /// Equal-tempered beginner piano note frequencies from C4 to C5.
  /// Black keys are included so kids learn the real piano keyboard pattern.
  static const Map<String, double> _noteFrequencies = {
    'C3': 130.81,
    'C#3': 138.59,
    'D3': 146.83,
    'D#3': 155.56,
    'E3': 164.81,
    'F3': 174.61,
    'F#3': 185.00,
    'G3': 196.00,
    'G#3': 207.65,
    'A3': 220.00,
    'A#3': 233.08,
    'B3': 246.94,
    'C4': 261.63,
    'C#': 277.18,
    'D': 293.66,
    'D#': 311.13,
    'E': 329.63,
    'F': 349.23,
    'F#': 369.99,
    'G': 392.00,
    'G#': 415.30,
    'A': 440.00,
    'A#': 466.16,
    'B': 493.88,
    'C#4': 277.18,
    'D4': 293.66,
    'D#4': 311.13,
    'E4': 329.63,
    'F4': 349.23,
    'F#4': 369.99,
    'G4': 392.00,
    'G#4': 415.30,
    'A4': 440.00,
    'A#4': 466.16,
    'B4': 493.88,
    'C5': 523.25,
  };

  static const Map<String, String> _keyboardNoteAliases = {
    'C3': 'C3',
    'C#3': 'C#3',
    'D3': 'D3',
    'D#3': 'D#3',
    'E3': 'E3',
    'F3': 'F3',
    'F#3': 'F#3',
    'G3': 'G3',
    'G#3': 'G#3',
    'A3': 'A3',
    'A#3': 'A#3',
    'B3': 'B3',
    'C4': 'C4',
    'C#4': 'C#4',
    'D4': 'D4',
    'D#4': 'D#4',
    'E4': 'E4',
    'F4': 'F4',
    'F#4': 'F#4',
    'G4': 'G4',
    'G#4': 'G#4',
    'A4': 'A4',
    'A#4': 'A#4',
    'B4': 'B4',
    'C5': 'C5',
    'C': 'C4',
    'C#': 'C#4',
    'D': 'D4',
    'D#': 'D#4',
    'E': 'E4',
    'F': 'F4',
    'F#': 'F#4',
    'G': 'G4',
    'G#': 'G#4',
    'A': 'A4',
    'A#': 'A#4',
    'B': 'B4',
    'High C': 'C5',
  };


  Future<void> playNote(String note) async {
    await playPianoNote(_normalizeKeyboardNote(note), duration: const Duration(milliseconds: 520));
  }

  /// Shared warm piano note path for lessons, songs, games, and live practice.
  ///
  /// Visible beginner notes reuse the same preloaded SoLoud sources as the Play
  /// Piano keyboard so lesson and song screens do not generate or load WAV data
  /// on the first press. If the shared cache cannot play a note, this safely
  /// falls back to the existing generated piano tone path.
  Future<void> playPianoNote(
    String note, {
    Duration duration = const Duration(milliseconds: 520),
  }) async {
    await _playPianoNoteForDuration(_normalizeKeyboardNote(note), duration);
  }

  /// Plays one short, naturally decaying keyboard note.
  ///
  /// This remains a one-shot compatibility path for non-press-aware callers.
  /// The Play Piano screen uses [startKeyboardNoteForPress] so each held key can
  /// own and release its sustain voice independently.
  void playKeyboardNote(String note) {
    final normalizedNote = _normalizeKeyboardNote(note);
    unawaited(
      _playPreloadedPianoNote(
        normalizedNote,
        waitForCache: false,
      ).then<void>((playedFromCache) async {
        if (playedFromCache) return;
        final frequency = _noteFrequencies[normalizedNote];
        if (frequency == null) return;
        await _playFallbackPianoTone(
          note: normalizedNote,
          frequency: frequency,
          durationMs: 700,
        );
      }),
    );
  }

  /// Starts the Play Piano live keyboard sound for a specific pointer press.
  ///
  /// Pointer down immediately triggers a bright attack sample and starts a soft
  /// sustain/resonance voice. The sustain handle is stored by [pressId], so
  /// chords can release one note without stopping the others.
  void startKeyboardNoteForPress(String note, int pressId) {
    note = _normalizeKeyboardNote(note);
    final debugNote = _debugNoteName(note);
    unawaited(_releaseKeyboardVoice(pressId, immediate: true));

    final attackSource = _keyboardAttackSoundByNote[note];
    final sustainSource = _keyboardSustainSoundByNote[note];
    if (!_isSoLoudReady || attackSource == null || sustainSource == null) {
      if (_keyboardDebugLogs) {
        debugPrint(
          'Keyboard press fallback: $debugNote generated memory sound is not ready',
        );
      }
      playKeyboardNote(note);
      return;
    }

    _playSoLoudKeyboardNote(
      debugNote: '$debugNote attack',
      source: attackSource,
      sampleInfo: _keyboardSampleInfoByNote[note],
      volume: 0.86,
    );

    final sustainHandle = _playSoLoudKeyboardNote(
      debugNote: '$debugNote sustain',
      source: sustainSource,
      sampleInfo: null,
      volume: 0.34,
    );
    if (sustainHandle == null) return;

    _activeKeyboardVoicesByPressId[pressId] = ActiveKeyboardVoice(
      pressId: pressId,
      note: note,
      handle: sustainHandle,
      startedAt: DateTime.now(),
    );
  }

  /// Releases only the sustain voice that belongs to [pressId]. Other held keys
  /// keep ringing, which preserves chord behavior.
  Future<void> stopKeyboardNoteForPress(int pressId) async {
    await _releaseKeyboardVoice(pressId);
  }

  /// Legacy API for non-keyboard callers. It now uses the same press-aware
  /// sustain model when a caller has a stable press ID.
  Future<void> startNote(String note) async {
    playKeyboardNote(_normalizeKeyboardNote(note));
  }

  /// Legacy press-aware API kept for screens that still pass pointer IDs.
  Future<void> startNoteForPress({
    required String note,
    required int pressId,
  }) async {
    startKeyboardNoteForPress(_normalizeKeyboardNote(note), pressId);
  }

  Future<void> stopNoteForPress(int pressId) async {
    await stopKeyboardNoteForPress(pressId);
  }

  Future<void> stopNote(String note) async {}

  String _normalizeKeyboardNote(String note) {
    return _keyboardNoteAliases[note] ?? note;
  }

  Future<void> playSuccess() async {
    await _playGeneratedMelody([523.25, 659.25, 783.99], noteDurationMs: 180);
  }

  Future<void> playTap() async {
    await playPianoNote('C', duration: const Duration(milliseconds: 180));
  }

  Future<void> playAnimalReward() async {
    await _playGeneratedMelody([392, 523.25, 659.25, 523.25], noteDurationMs: 190);
  }

  Future<void> playSongNotes(List<String> notes) async {
    for (final note in notes) {
      await playNote(note);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> playSongDemo(Song song) async {
    final token = ++_songDemoToken;
    await stopAllNotes();

    for (final step in song.steps) {
      if (token != _songDemoToken) return;

      final duration = song.durationForBeats(
        step.beats,
        tempoMultiplier: _demoTempoMultiplier,
      );
      final note = step.note;
      if (note == null) {
        await Future<void>.delayed(duration);
        continue;
      }

      await _playPianoNoteForDuration(_normalizeKeyboardNote(note), duration);
    }
  }

  Future<void> stopAllNotes() async {
    final pressIds = List<int>.of(_activeKeyboardVoicesByPressId.keys);
    await Future.wait<void>([
      for (final pressId in pressIds)
        _releaseKeyboardVoice(pressId, immediate: true),
    ]);
  }

  Future<void> _initializeKeyboardAudio() async {
    await Future.wait<void>([
      _prepareSoLoudKeyboardCache(),
    ]);
  }

  Future<void> _prepareSoLoudKeyboardCache() async {
    try {
      if (!_soloud.isInitialized) await _soloud.init();

      // Only preload the notes that are visible on the beginner keyboard. This
      // keeps the live keyboard path small and avoids an 88-note cache for now.
      for (final entry in _noteFrequencies.entries) {
        final debugNote = _debugNoteName(entry.key);
        final oneShotSample = _useDiagnosticClickTone
            ? _buildDiagnosticClickToneWav(frequency: entry.value)
            : _buildWarmWoodPianoWav(
                frequency: entry.value,
                durationMs: _keyboardNoteDurationMs,
                volume: 0.82,
                velocity: 1.0,
                liveKeyboard: true,
              );
        final attackSample = _useDiagnosticClickTone
            ? _buildDiagnosticClickToneWav(frequency: entry.value)
            : _buildWarmWoodPianoWav(
                frequency: entry.value,
                durationMs: _keyboardAttackDurationMs,
                volume: 0.86,
                velocity: 1.0,
                liveKeyboard: true,
              );
        final sustainSample = _useDiagnosticClickTone
            ? _buildDiagnosticClickToneWav(frequency: entry.value)
            : _buildWarmWoodPianoWav(
                frequency: entry.value,
                durationMs: _keyboardSustainDurationMs,
                volume: 0.38,
                velocity: 0.62,
                liveKeyboard: true,
                sustainLayer: true,
              );
        if (_keyboardDebugLogs) {
          debugPrint(
            'Live attack sample $debugNote = ${attackSample.info.durationMs}ms; '
            'first non-zero sample at ${attackSample.info.firstNonZeroSampleMs}ms; '
            'attack peak within first 30ms = ${attackSample.info.attackPeakWithinFirst30Ms}',
          );
          debugPrint(
            'Live sustain sample $debugNote = ${sustainSample.info.durationMs}ms; '
            'first non-zero sample at ${sustainSample.info.firstNonZeroSampleMs}ms',
          );
        }
        _keyboardSoundByNote[entry.key] = await _soloud.loadMem(
          '$debugNote-one-shot.wav',
          oneShotSample.bytes,
          mode: LoadMode.memory,
        );
        _keyboardAttackSoundByNote[entry.key] = await _soloud.loadMem(
          '$debugNote-attack.wav',
          attackSample.bytes,
          mode: LoadMode.memory,
        );
        _keyboardSustainSoundByNote[entry.key] = await _soloud.loadMem(
          '$debugNote-sustain.wav',
          sustainSample.bytes,
          mode: LoadMode.memory,
        );
        _keyboardSampleInfoByNote[entry.key] = oneShotSample.info;
      }

      _isSoLoudReady =
          _keyboardSoundByNote.length == _noteFrequencies.length &&
          _keyboardAttackSoundByNote.length == _noteFrequencies.length &&
          _keyboardSustainSoundByNote.length == _noteFrequencies.length;
      _keyboardCacheReadyNotifier.value = _isSoLoudReady;
      debugPrint(
        'SoLoud keyboard cache ready: ${_keyboardSoundByNote.length} notes',
      );
    } catch (error) {
      _isSoLoudReady = false;
      _keyboardCacheReadyNotifier.value = false;
      debugPrint('SoLoud keyboard cache skipped. Error: $error');
    }
  }

  SoundHandle? _playSoLoudKeyboardNote({
    required String debugNote,
    required AudioSource source,
    required _KeyboardSampleInfo? sampleInfo,
    double volume = 0.86,
  }) {
    if (_keyboardDebugLogs) {
      final beforePlayMs = DateTime.now().millisecondsSinceEpoch;
      debugPrint('SoLoud play called $debugNote at ${beforePlayMs}ms');
      if (sampleInfo != null) {
        debugPrint(
          'Live sample duration $debugNote = ${sampleInfo.durationMs}ms; '
          'first non-zero sample at ${sampleInfo.firstNonZeroSampleMs}ms; '
          'attack peak within first 30ms = ${sampleInfo.attackPeakWithinFirst30Ms}',
        );
      }
    }

    try {
      final voice = _soloud.play(source, volume: volume);
      if (_keyboardDebugLogs) {
        final afterPlayMs = DateTime.now().millisecondsSinceEpoch;
        debugPrint(
          'SoLoud voice started: $debugNote voice=$voice at ${afterPlayMs}ms',
        );
      }
      return voice;
    } catch (error) {
      debugPrint(
        'Keyboard note skipped: $debugNote SoLoud play failed. Error: $error',
      );
      return null;
    }
  }

  Future<void> _playPianoNoteForDuration(String note, Duration duration) async {
    final debugNote = _debugNoteName(note);
    final frequency = _noteFrequencies[note];
    if (frequency == null) {
      debugPrint('No generated frequency for note: $debugNote');
      await Future<void>.delayed(duration);
      return;
    }

    final noteMilliseconds = duration.inMilliseconds;
    final gapMilliseconds = noteMilliseconds <= _songGapMs
        ? 0
        : math.min(_songGapMs, (noteMilliseconds * 0.12).round());
    final playMilliseconds = math.max(1, noteMilliseconds - gapMilliseconds);

    final playedFromCache = await _playPreloadedPianoNote(
      note,
      waitForCache: true,
    );
    if (!playedFromCache) {
      await _playFallbackPianoTone(
        note: note,
        frequency: frequency,
        durationMs: playMilliseconds,
      );
    } else {
      await Future<void>.delayed(Duration(milliseconds: playMilliseconds));
    }
    if (gapMilliseconds > 0) {
      await Future<void>.delayed(Duration(milliseconds: gapMilliseconds));
    }
  }

  Future<void> _releaseKeyboardVoice(
    int pressId, {
    bool immediate = false,
  }) async {
    final voice = _activeKeyboardVoicesByPressId.remove(pressId);
    if (voice == null) return;

    try {
      if (!immediate) {
        _soloud.fadeVolume(voice.handle, 0.0, _keyboardReleaseFadeDuration);
        await Future<void>.delayed(_keyboardReleaseFadeDuration);
      }
      await _soloud.stop(voice.handle);
    } catch (error) {
      if (_keyboardDebugLogs) {
        debugPrint(
          'Keyboard sustain release skipped: ${_debugNoteName(voice.note)} '
          'press=$pressId. Error: $error',
        );
      }
    }
  }

  Future<bool> _playPreloadedPianoNote(
    String note, {
    required bool waitForCache,
  }) async {
    final debugNote = _debugNoteName(note);

    if (!_noteFrequencies.containsKey(note)) {
      debugPrint('Piano note skipped: $debugNote has no visible-key frequency');
      return false;
    }

    if (waitForCache && !_isSoLoudReady) {
      try {
        await keyboardCacheReady.timeout(_audioStartTimeout);
      } catch (error) {
        debugPrint('Piano cache wait skipped for $debugNote. Error: $error');
      }
    }

    final source = _keyboardSoundByNote[note];
    if (!_isSoLoudReady || source == null) {
      if (_keyboardDebugLogs) {
        debugPrint('Piano note skipped: $debugNote SoLoud cache is not ready');
      }
      return false;
    }

    if (_keyboardDebugLogs) {
      final requestedAtMs = DateTime.now().millisecondsSinceEpoch;
      debugPrint('Piano note triggered: $debugNote at ${requestedAtMs}ms');
    }

    final handle = _playSoLoudKeyboardNote(
      debugNote: debugNote,
      source: source,
      sampleInfo: _keyboardSampleInfoByNote[note],
    );
    return handle != null;
  }

  Future<void> _playFallbackPianoTone({
    required String note,
    required double frequency,
    required int durationMs,
  }) async {
    final player = AudioPlayer();
    try {
      if (_keyboardDebugLogs) {
        debugPrint('Using generated note: ${_debugNoteName(note)}');
      }
      await _playGeneratedTone(
        player: player,
        frequency: frequency,
        durationMs: durationMs,
        volume: 0.58,
        velocity: 0.72,
      );

      await Future<void>.delayed(Duration(milliseconds: durationMs));
      await player.stop();
    } finally {
      await player.dispose();
    }
  }

  Future<void> _playGeneratedMelody(
    List<double> frequencies, {
    required int noteDurationMs,
  }) async {
    for (final frequency in frequencies) {
      await _playGeneratedTone(
        player: _effectsPlayer,
        frequency: frequency,
        durationMs: noteDurationMs,
        volume: 0.46,
        velocity: 0.66,
      );
      await Future<void>.delayed(const Duration(milliseconds: 45));
    }
  }

  Future<void> _playGeneratedTone({
    required AudioPlayer player,
    required double frequency,
    required int durationMs,
    required double volume,
    required double velocity,
  }) async {
    try {
      await player.stop();
      final sample = _buildWarmWoodPianoWav(
        frequency: frequency,
        durationMs: durationMs,
        volume: volume,
        velocity: velocity,
      );
      if (_keyboardDebugLogs) {
        debugPrint('Generated WAV bytes length: ${sample.bytes.length}');
      }
      await player
          .play(BytesSource(sample.bytes, mimeType: 'audio/wav'))
          .timeout(_audioStartTimeout);
    } catch (error) {
      // Audio should never block the child from using the app.
      debugPrint('Generated piano tone skipped. Error: $error');
    }
  }

  String _debugNoteName(String note) {
    if (note == 'High C') return 'C5';
    return '${note}4';
  }

  _GeneratedPianoWav _buildDiagnosticClickToneWav({required double frequency}) {
    const durationMs = 70;
    final totalSamples = (_sampleRate * durationMs / 1000).round();
    final pcmBytes = BytesBuilder(copy: false);
    var peak = 0.0;
    var firstNonZeroSampleIndex = -1;
    var first30MsPeak = 0.0;
    final first30SampleCount = (_sampleRate * 0.030).round();
    final samples = List<double>.filled(totalSamples, 0);

    for (var i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      final envelope = math.exp(-t * 65.0);
      final clickEnvelope = math.exp(-t * 260.0);
      final tone = math.sin(2 * math.pi * frequency * t) * 0.75;
      final click = math.sin(2 * math.pi * 2200.0 * t) * 0.45;
      final sample = (tone * envelope + click * clickEnvelope) * 0.9;
      samples[i] = sample;

      final framePeak = sample.abs();
      if (framePeak > peak) peak = framePeak;
      if (firstNonZeroSampleIndex == -1 && framePeak > 0.00003) {
        firstNonZeroSampleIndex = i;
      }
      if (i < first30SampleCount && framePeak > first30MsPeak) {
        first30MsPeak = framePeak;
      }
    }

    final normalizeGain = peak <= 0 ? 1.0 : math.min(1.8, 0.9 / peak);
    for (final sample in samples) {
      final value = _toInt16(_softClip(sample * normalizeGain));
      pcmBytes
        ..addByte(value & 0xff)
        ..addByte((value >> 8) & 0xff)
        ..addByte(value & 0xff)
        ..addByte((value >> 8) & 0xff);
    }

    final firstNonZeroMs = firstNonZeroSampleIndex < 0
        ? -1
        : (firstNonZeroSampleIndex * 1000 / _sampleRate).round();
    return _GeneratedPianoWav(
      bytes: _wrapPcmAsWav(pcmBytes.takeBytes()),
      info: _KeyboardSampleInfo(
        durationMs: durationMs,
        firstNonZeroSampleMs: firstNonZeroMs,
        attackPeakWithinFirst30Ms: first30MsPeak * normalizeGain >= 0.22,
      ),
    );
  }

  /// Builds a small stereo WAV file that is warmer and more natural than a beep.
  ///
  /// The synthesis uses a few simple acoustic-piano ideas:
  /// - three slightly detuned virtual strings per note
  /// - quick hammer attack
  /// - natural exponential decay
  /// - harmonic partials that decay faster at higher frequencies
  /// - a tiny hammer/noise transient
  /// - soft saturation instead of hard clipping
  /// - subtle stereo spread for a soundboard-like feeling
  _GeneratedPianoWav _buildWarmWoodPianoWav({
    required double frequency,
    required int durationMs,
    required double volume,
    required double velocity,
    bool liveKeyboard = false,
    bool sustainLayer = false,
  }) {
    final totalSamples = (_sampleRate * durationMs / 1000).round();
    final normalizedSamples = List<double>.filled(totalSamples * _channels, 0);
    final pcmBytes = BytesBuilder(copy: false);
    var peak = 0.0;
    var firstNonZeroSampleIndex = -1;
    var first30MsPeak = 0.0;
    final first30SampleCount = (_sampleRate * 0.030).round();

    // Higher keys naturally fade a little faster. Lower keys feel warmer.
    final keyPosition = ((frequency - 261.63) / (523.25 - 261.63))
        .clamp(0.0, 1.0);
    final mainDecay = sustainLayer
        ? 2.8 + keyPosition * 0.9
        : liveKeyboard
        ? 8.4 + keyPosition * 2.4
        : 2.15 + keyPosition * 1.28;
    final bodyDecay = sustainLayer
        ? 1.35 + keyPosition * 0.45
        : liveKeyboard
        ? 13.8 + keyPosition * 3.2
        : 1.08 + keyPosition * 0.7;
    final brightness = sustainLayer
        ? 0.66 + keyPosition * 0.12
        : liveKeyboard
        ? 0.98 + keyPosition * 0.28
        : 0.88 + keyPosition * 0.22;

    for (var i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / totalSamples;

      // Live keyboard samples must be audible immediately. Use an instant
      // attack floor with a very fast ramp instead of a soft fade-in.
      final attack = sustainLayer
          ? 0.72 + 0.28 * (1.0 - math.exp(-t * 520.0))
          : liveKeyboard
          ? 0.9 + 0.1 * (1.0 - math.exp(-t * 1800.0))
          : 1.0 - math.exp(-t * 420.0);
      final stringDecay = sustainLayer
          ? 0.66 * math.exp(-mainDecay * progress) +
              0.34 * math.exp(-bodyDecay * progress)
          : liveKeyboard
          ? 0.96 * math.exp(-mainDecay * progress) +
              0.04 * math.exp(-bodyDecay * progress)
          : 0.78 * math.exp(-mainDecay * progress) +
              0.22 * math.exp(-bodyDecay * progress);
      final releaseStart = sustainLayer
          ? 0.72
          : liveKeyboard
          ? 0.54
          : 0.86;
      final releaseLength = 1.0 - releaseStart;
      final release = progress > releaseStart
          ? (1.0 - progress) / releaseLength
          : 1.0;
      final envelope = attack * stringDecay * release.clamp(0.0, 1.0);

      final left = _pianoSample(
        t: t,
        frequency: frequency,
        velocity: velocity,
        brightness: brightness,
        detuneDirection: -1,
      );
      final right = _pianoSample(
        t: t,
        frequency: frequency,
        velocity: velocity,
        brightness: brightness,
        detuneDirection: 1,
      );

      // Very short hammer transient adds acoustic touch but remains gentle.
      final hammer = _hammerTransient(
        t,
        frequency,
        velocity,
        liveKeyboard: liveKeyboard,
        sustainLayer: sustainLayer,
      );
      final body = _woodBodyResonance(
        t,
        frequency,
        keyPosition,
        liveKeyboard: liveKeyboard,
        sustainLayer: sustainLayer,
      );

      final hammerLeft = sustainLayer
          ? hammer * 0.16
          : liveKeyboard
          ? hammer * 0.9
          : hammer * 0.58;
      final hammerRight = sustainLayer
          ? hammer * 0.14
          : liveKeyboard
          ? hammer * 0.78
          : hammer * 0.48;
      final leftRaw = ((left + body) * envelope + hammerLeft) * volume;
      final rightRaw = ((right + body) * envelope + hammerRight) * volume;
      normalizedSamples[i * _channels] = leftRaw;
      normalizedSamples[i * _channels + 1] = rightRaw;

      final framePeak = math.max(leftRaw.abs(), rightRaw.abs());
      if (framePeak > peak) peak = framePeak;
      if (firstNonZeroSampleIndex == -1 && framePeak > 0.00003) {
        firstNonZeroSampleIndex = i;
      }
      if (i < first30SampleCount && framePeak > first30MsPeak) {
        first30MsPeak = framePeak;
      }
    }

    final targetPeak = sustainLayer
        ? 0.48
        : liveKeyboard
        ? 0.82
        : 0.8;
    final normalizeGain = peak <= 0 ? 1.0 : math.min(2.1, targetPeak / peak);
    for (var i = 0; i < totalSamples; i++) {
      final leftValue = _toInt16(
        _softClip(normalizedSamples[i * _channels] * normalizeGain),
      );
      final rightValue = _toInt16(
        _softClip(normalizedSamples[i * _channels + 1] * normalizeGain),
      );

      pcmBytes
        ..addByte(leftValue & 0xff)
        ..addByte((leftValue >> 8) & 0xff)
        ..addByte(rightValue & 0xff)
        ..addByte((rightValue >> 8) & 0xff);
    }

    final pcmData = pcmBytes.takeBytes();
    final firstNonZeroMs = firstNonZeroSampleIndex < 0
        ? -1
        : (firstNonZeroSampleIndex * 1000 / _sampleRate).round();
    final attackPeakWithinFirst30Ms = first30MsPeak * normalizeGain >= 0.22;
    return _GeneratedPianoWav(
      bytes: _wrapPcmAsWav(pcmData),
      info: _KeyboardSampleInfo(
        durationMs: durationMs,
        firstNonZeroSampleMs: firstNonZeroMs,
        attackPeakWithinFirst30Ms: attackPeakWithinFirst30Ms,
      ),
    );
  }

  double _pianoSample({
    required double t,
    required double frequency,
    required double velocity,
    required double brightness,
    required int detuneDirection,
  }) {
    // Three virtual strings, like an acoustic piano note, with very small
    // detuning. This creates a gentle chorus/wooden resonance.
    final detunes = <double>[
      1.0,
      1.0 + detuneDirection * 0.0018,
      1.0 - detuneDirection * 0.0012,
    ];

    var sample = 0.0;
    for (final detune in detunes) {
      final f = frequency * detune;
      sample += _harmonic(f, t, 1, 1.00);
      sample += _harmonic(f, t, 2, 0.42 * brightness);
      sample += _harmonic(f, t, 3, 0.22 * brightness);
      sample += _harmonic(f, t, 4, 0.095 * brightness);
      sample += _harmonic(f, t, 5, 0.052 * brightness);
      sample += _harmonic(f, t, 6, 0.028 * brightness);
      sample += _harmonic(f, t, 8, 0.012 * brightness);
    }

    // Velocity changes timbre: harder notes are slightly brighter.
    final velocityBrightness = 0.88 + velocity * 0.18;
    return sample / detunes.length * velocityBrightness * 0.52;
  }

  double _harmonic(double baseFrequency, double t, int harmonic, double amount) {
    // Higher harmonics decay a little faster, reducing synthetic harshness.
    final harmonicDecay = math.exp(-t * harmonic * 0.62);
    return amount *
        harmonicDecay *
        math.sin(2 * math.pi * baseFrequency * harmonic * t);
  }

  double _hammerTransient(
    double t,
    double frequency,
    double velocity, {
    bool liveKeyboard = false,
    bool sustainLayer = false,
  }) {
    final transient = math.exp(
      -t * (sustainLayer ? 135.0 : liveKeyboard ? 170.0 : 105.0),
    );
    final clickTone = math.sin(2 * math.pi * frequency * 7.0 * t);
    final woodyTap =
        math.sin(2 * math.pi * 1900.0 * t) *
        (sustainLayer ? 0.12 : liveKeyboard ? 0.42 : 0.28);
    final softNoise = _deterministicNoise(t) *
        (sustainLayer ? 0.05 : liveKeyboard ? 0.14 : 0.12);
    final amount = sustainLayer ? 0.055 : liveKeyboard ? 0.24 : 0.12;
    return transient * velocity * amount * (clickTone + woodyTap + softNoise);
  }

  double _woodBodyResonance(
    double t,
    double frequency,
    double keyPosition, {
    bool liveKeyboard = false,
    bool sustainLayer = false,
  }) {
    // Subtle resonances give a small soundboard/body feeling.
    final bodyAmount =
        (sustainLayer ? 0.014 : liveKeyboard ? 0.008 : 0.024) *
        (1.0 - keyPosition * 0.35);
    final bodyDecay = math.exp(
      -t * (sustainLayer ? 1.55 : liveKeyboard ? 18.0 : 2.35),
    );
    final body1 = math.sin(2 * math.pi * (frequency * 0.5) * t) * 0.55;
    final body2 = math.sin(2 * math.pi * (frequency * 1.5) * t) * 0.25;
    final body3 = math.sin(2 * math.pi * 176.0 * t) * 0.20;
    return bodyAmount * bodyDecay * (body1 + body2 + body3);
  }

  /// Tiny deterministic noise for the hammer transient.
  /// This avoids importing random generators and keeps output stable.
  double _deterministicNoise(double t) {
    final x = math.sin((t * 44100.0 + 12.9898) * 78.233) * 43758.5453;
    return 2.0 * (x - x.floor()) - 1.0;
  }

  /// Smoothly limits the waveform to avoid harsh clipping.
  /// Dart's math library does not include tanh() on all Flutter versions,
  /// so we use an equivalent exponential implementation.
  double _softClip(double x) {
    if (x > 12) return 1;
    if (x < -12) return -1;
    final e = math.exp(2 * x);
    return (e - 1) / (e + 1);
  }

  int _toInt16(double sample) {
    return (sample * 32767).clamp(-32768, 32767).round();
  }

  Uint8List _wrapPcmAsWav(Uint8List pcmData) {
    final byteRate = _sampleRate * _channels * _bitsPerSample ~/ 8;
    final blockAlign = _channels * _bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final output = BytesBuilder(copy: false);
    output.add(_ascii('RIFF'));
    output.add(_uint32(fileSize));
    output.add(_ascii('WAVE'));
    output.add(_ascii('fmt '));
    output.add(_uint32(16));
    output.add(_uint16(1)); // PCM format.
    output.add(_uint16(_channels));
    output.add(_uint32(_sampleRate));
    output.add(_uint32(byteRate));
    output.add(_uint16(blockAlign));
    output.add(_uint16(_bitsPerSample));
    output.add(_ascii('data'));
    output.add(_uint32(dataSize));
    output.add(pcmData);
    return output.takeBytes();
  }

  Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);

  Uint8List _uint16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Uint8List _uint32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Future<void> dispose() async {
    _songDemoToken++;
    await stopAllNotes();

    for (final source in [
      ..._keyboardSoundByNote.values,
      ..._keyboardAttackSoundByNote.values,
      ..._keyboardSustainSoundByNote.values,
    ]) {
      try {
        await _soloud.disposeSource(source);
      } catch (error) {
        debugPrint('SoLoud keyboard source dispose skipped. Error: $error');
      }
    }
    _keyboardSoundByNote.clear();
    _keyboardAttackSoundByNote.clear();
    _keyboardSustainSoundByNote.clear();
    _keyboardSampleInfoByNote.clear();

    try {
      _soloud.deinit();
    } catch (error) {
      debugPrint('SoLoud deinit skipped. Error: $error');
    }

    _keyboardCacheReadyNotifier.dispose();
    await _effectsPlayer.dispose();
  }
}

class ActiveKeyboardVoice {
  const ActiveKeyboardVoice({
    required this.pressId,
    required this.note,
    required this.handle,
    required this.startedAt,
  });

  final int pressId;
  final String note;
  final SoundHandle handle;
  final DateTime startedAt;
}

class _GeneratedPianoWav {
  const _GeneratedPianoWav({
    required this.bytes,
    required this.info,
  });

  final Uint8List bytes;
  final _KeyboardSampleInfo info;
}

class _KeyboardSampleInfo {
  const _KeyboardSampleInfo({
    required this.durationMs,
    required this.firstNonZeroSampleMs,
    required this.attackPeakWithinFirst30Ms,
  });

  final int durationMs;
  final int firstNonZeroSampleMs;
  final bool attackPeakWithinFirst30Ms;
}
