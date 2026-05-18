import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/song.dart';

class _ActivePianoVoice {
  _ActivePianoVoice({required this.pointerId, required this.note})
      : pressedAt = DateTime.now();

  final int pointerId;
  final String note;
  final AudioPlayer player = AudioPlayer();
  final DateTime pressedAt;
  DateTime? releasedAt;
  DateTime? startedAt;
  bool isReleased = false;
  bool isStopping = false;
  bool disposed = false;

  bool get hasStarted => startedAt != null;
}

/// Audio service for Happy Piano Kids.
///
/// Audio strategy:
/// 1. Try to play real piano samples from assets.
/// 2. If a sample is missing, generate a warm acoustic-style piano tone.
/// 3. If audio fails, skip safely so the child can continue using the app.
///
/// Important: the generated tone is not a copyrighted sample or exact clone of
/// Steinway, Yamaha, or any other brand. It is a brand-inspired, synthetic,
/// wood-piano-like tone designed for a kid-friendly MVP.
class AudioService {
  AudioService() {
    unawaited(_loadAssetManifest());
    _keyboardToneCacheReady = _prepareKeyboardToneCache();
    unawaited(_keyboardToneCacheReady);
  }

  final AudioPlayer _effectsPlayer = AudioPlayer();
  final Map<int, _ActivePianoVoice> _activeVoicesByPressId = {};
  final Map<String, Set<int>> _activePressIdsByNote = {};
  var _nextSyntheticPressId = 0;
  final Map<String, bool> _assetAvailabilityByNote = {};
  final Map<String, Uint8List> _keyboardToneBytesByNote = {};
  late final Future<void> _keyboardToneCacheReady;
  var _songDemoToken = 0;

  static const double _demoTempoMultiplier = 1.0;
  static const int _songGapMs = 45;
  static const int _minimumAudibleNoteMs = 150;
  static const int _heldNoteGeneratedDurationMs = 8000;
  static const Duration _audioStartTimeout = Duration(milliseconds: 900);

  static const int _sampleRate = 44100;
  static const int _channels = 2;
  static const int _bitsPerSample = 16;

  static const Map<String, String> _noteFiles = {
    'C': 'audio/notes/c.mp3',
    'C#': 'audio/notes/c_sharp.mp3',
    'D': 'audio/notes/d.mp3',
    'D#': 'audio/notes/d_sharp.mp3',
    'E': 'audio/notes/e.mp3',
    'F': 'audio/notes/f.mp3',
    'F#': 'audio/notes/f_sharp.mp3',
    'G': 'audio/notes/g.mp3',
    'G#': 'audio/notes/g_sharp.mp3',
    'A': 'audio/notes/a.mp3',
    'A#': 'audio/notes/a_sharp.mp3',
    'B': 'audio/notes/b.mp3',
    'High C': 'audio/notes/high_c.mp3',
  };

  /// Equal-tempered beginner piano note frequencies from C4 to C5.
  /// Black keys are included so kids learn the real piano keyboard pattern.
  static const Map<String, double> _noteFrequencies = {
    'C': 261.63,
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
    'High C': 523.25,
  };

  Future<void> playNote(String note) async {
    final pressId = _nextLegacyPressId();
    await startNoteForPress(note: note, pressId: pressId);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    await stopNoteForPress(pressId);
  }

  /// Starts a note for callers that do not have a pointer/press id.
  ///
  /// Keyboard widgets should prefer [startNoteForPress] so each physical press
  /// owns exactly one player and quick re-taps are not blocked by release
  /// cleanup from an older press.
  Future<void> startNote(String note) {
    return startNoteForPress(note: note, pressId: _nextLegacyPressId());
  }

  /// Starts one piano voice for one physical key press.
  ///
  /// The [pressId] comes from the keyboard pointer tracking layer. A duplicate
  /// down event for the same press id is ignored, but any other press id, even
  /// for another note or a quick re-tap of the same note, can start immediately.
  Future<void> startNoteForPress({required String note, required int pressId}) {
    final debugNote = _debugNoteName(note);
    final existingVoice = _activeVoicesByPressId[pressId];
    if (existingVoice != null) {
      if (existingVoice.note == note && !existingVoice.isReleased) {
        debugPrint('Press $pressId already active for $debugNote');
        return Future<void>.value();
      }

      debugPrint(
        'Press $pressId moved from ${_debugNoteName(existingVoice.note)} to $debugNote; stopping old voice',
      );
      unawaited(stopNoteForPress(pressId));
    }

    final frequency = _noteFrequencies[note];
    if (frequency == null) {
      debugPrint('No generated frequency for note: $debugNote');
      return Future<void>.value();
    }

    final voice = _ActivePianoVoice(pointerId: pressId, note: note);
    _activeVoicesByPressId[pressId] = voice;
    _activePressIdsByNote.putIfAbsent(note, () => <int>{}).add(pressId);

    // Keyboard playback uses one primary player for each active physical press.
    // This preserves polyphony, allows quick re-taps, and prevents duplicate
    // starts from repeated down events for the same press id.
    debugPrint('Starting press $pressId $debugNote');
    unawaited(_playKeyboardNote(voice));
    return Future<void>.value();
  }

  /// Stops only the voice owned by [pressId].
  Future<void> stopNoteForPress(int pressId) async {
    final voice = _activeVoicesByPressId[pressId];
    if (voice == null) return;

    final debugNote = _debugNoteName(voice.note);
    voice.isReleased = true;
    voice.releasedAt = DateTime.now();

    if (!voice.hasStarted) {
      debugPrint('Press released before player started: $debugNote');
      return;
    }

    await _stopAndDisposeVoice(voice);
  }

  Future<void> stopNote(String note) async {
    final pressIds = _activePressIdsByNote[note]?.toList();
    if (pressIds == null || pressIds.isEmpty) return;

    for (final pressId in pressIds) {
      await stopNoteForPress(pressId);
    }
  }

  Future<void> playSuccess() async {
    await _playGeneratedMelody([523.25, 659.25, 783.99], noteDurationMs: 180);
  }

  Future<void> playTap() async {
    await _playGeneratedTone(
      player: _effectsPlayer,
      frequency: 880,
      durationMs: 100,
      volume: 0.26,
      velocity: 0.45,
    );
  }

  Future<void> playAnimalReward() async {
    await _playGeneratedMelody([392, 523.25, 659.25, 523.25], noteDurationMs: 140);
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

      await _playSongDemoNote(note, duration);
    }
  }

  Future<void> stopAllNotes() async {
    final pressIds = _activeVoicesByPressId.keys.toList();
    for (final pressId in pressIds) {
      await stopNoteForPress(pressId);
    }
  }

  Future<void> _loadAssetManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final availableAssets = manifest.listAssets().toSet();

      for (final entry in _noteFiles.entries) {
        final assetPath = entry.value;
        final bundledPath = 'assets/$assetPath';
        _assetAvailabilityByNote[entry.key] =
            availableAssets.contains(assetPath) ||
            availableAssets.contains(bundledPath);
      }
    } catch (error) {
      debugPrint(
        'Asset manifest unavailable. Using generated piano tones. Error: $error',
      );
      for (final note in _noteFiles.keys) {
        _assetAvailabilityByNote[note] = false;
      }
    }
  }

  Future<void> _prepareKeyboardToneFileCache() async {
    try {
      // Yield out of the service constructor before doing the heavier WAV
      // synthesis work, then keep the resulting bytes in memory for all
      // keyboard presses.
      await Future<void>.delayed(Duration.zero);

      for (final entry in _noteFrequencies.entries) {
        _keyboardToneBytesByNote[entry.key] = _buildWarmWoodPianoWav(
          frequency: entry.value,
          durationMs: _heldNoteGeneratedDurationMs,
          volume: 0.52,
          velocity: 0.72,
        );
      }
      debugPrint('Tone cache ready for keyboard');
    } catch (error) {
      debugPrint('Generated tone cache skipped. Error: $error');
    }
  }

  Future<bool> _tryPlayAsset(
    AudioPlayer player,
    String note,
    String assetPath,
  ) async {
    try {
      await player.play(AssetSource(assetPath));
      return true;
    } catch (error) {
      _assetAvailabilityByNote[note] = false;
      debugPrint(
        'Asset unavailable, skipping asset attempt: ${_debugNoteName(note)}',
      );
      return false;
    }
  }

  Future<void> _playSongDemoNote(String note, Duration duration) async {
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

    final player = AudioPlayer();
    try {
      final assetPath = _noteFiles[note];
      var playedAsset = false;
      if (assetPath != null && _assetAvailabilityByNote[note] == true) {
        debugPrint('Using bundled asset note: $debugNote');
        playedAsset = await _tryPlayAsset(player, note, assetPath);
      } else if (assetPath != null) {
        debugPrint('Asset unavailable, skipping asset attempt: $debugNote');
      }

      if (!playedAsset) {
        debugPrint('Using generated note: $debugNote');
        await _playGeneratedTone(
          player: player,
          frequency: frequency,
          durationMs: playMilliseconds,
          volume: 0.54,
          velocity: 0.68,
        );
      }

      await Future<void>.delayed(Duration(milliseconds: playMilliseconds));
      await player.stop();
      if (gapMilliseconds > 0) {
        await Future<void>.delayed(Duration(milliseconds: gapMilliseconds));
      }
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
        volume: 0.38,
        velocity: 0.62,
      );
      await Future<void>.delayed(const Duration(milliseconds: 45));
    }
  }

  Future<void> _playKeyboardNote(_ActivePianoVoice voice) async {
    final note = voice.note;
    final debugNote = _debugNoteName(note);
    try {
      await voice.player.setReleaseMode(ReleaseMode.stop);

      final assetPath = _noteFiles[note];
      var playedAsset = false;
      if (assetPath != null && _assetAvailabilityByNote[note] == true) {
        debugPrint('Using bundled asset note: $debugNote');
        playedAsset = await _tryPlayAsset(voice.player, note, assetPath);
      }

      if (!playedAsset) {
        await _keyboardToneCacheReady;
        if (_activeVoicesByPressId[voice.pointerId] != voice || voice.disposed) {
          await _disposeFailedVoice(voice);
          return;
        }

        final bytes = _keyboardToneBytesByNote[note];
        if (bytes == null) {
          debugPrint('No cached sustain tone for $debugNote');
          await _disposeFailedVoice(voice);
          return;
        }

        debugPrint('Using cached sustain tone: $debugNote');
        await voice.player
            .play(BytesSource(bytes, mimeType: 'audio/wav'))
            .timeout(_audioStartTimeout);
      }

      if (_activeVoicesByPressId[voice.pointerId] != voice || voice.disposed) {
        await _disposeFailedVoice(voice);
        return;
      }

      voice.startedAt = DateTime.now();
      debugPrint('Player started press ${voice.pointerId} $debugNote');

      if (voice.isReleased) {
        await _stopAndDisposeVoice(voice);
      }
    } on TimeoutException {
      debugPrint('Generated piano tone start timed out for $debugNote.');
      await _disposeFailedVoice(voice);
    } catch (error) {
      debugPrint('Generated piano tone skipped for $debugNote. Error: $error');
      await _disposeFailedVoice(voice);
    }
  }

  Future<void> _stopAndDisposeVoice(_ActivePianoVoice voice) async {
    if (voice.disposed || voice.isStopping) return;
    voice.isStopping = true;

    final note = voice.note;
    final debugNote = _debugNoteName(note);
    final startedAt = voice.startedAt;
    if (startedAt != null) {
      final playingFor = DateTime.now()
          .difference(startedAt)
          .inMilliseconds;
      final remainingMs = _minimumAudibleNoteMs - playingFor;
      if (remainingMs > 0) {
        debugPrint('Minimum tap release scheduled: $debugNote');
        await Future<void>.delayed(Duration(milliseconds: remainingMs));
      }
    }

    _removeActiveVoice(voice);
    voice.disposed = true;

    try {
      debugPrint('Stopped press ${voice.pointerId} $debugNote');
      await voice.player.stop();
    } catch (error) {
      debugPrint('Piano note stop skipped for $debugNote. Error: $error');
    } finally {
      try {
        await voice.player.dispose();
      } catch (_) {
        // Audio cleanup should never break the app.
      }
    }
  }

  Future<void> _disposeFailedVoice(_ActivePianoVoice voice) async {
    if (voice.disposed) return;
    _removeActiveVoice(voice);
    voice.disposed = true;
    try {
      await voice.player.stop();
    } catch (_) {
      // Audio cleanup should never break the app.
    } finally {
      try {
        await voice.player.dispose();
      } catch (_) {
        // Audio cleanup should never break the app.
      }
    }
  }

  void _removeActiveVoice(_ActivePianoVoice voice) {
    final currentVoice = _activeVoicesByPressId[voice.pointerId];
    final voiceStillRegistered = currentVoice == voice;
    if (voiceStillRegistered) {
      _activeVoicesByPressId.remove(voice.pointerId);
    }

    // If the platform ever reuses a pointer id before an older voice finishes
    // its quick-tap release, do not remove the newer voice's note lookup.
    if (voiceStillRegistered || currentVoice?.note != voice.note) {
      final pressIdsForNote = _activePressIdsByNote[voice.note];
      pressIdsForNote?.remove(voice.pointerId);
      if (pressIdsForNote != null && pressIdsForNote.isEmpty) {
        _activePressIdsByNote.remove(voice.note);
      }
    }
  }

  int _nextLegacyPressId() {
    _nextSyntheticPressId--;
    return _nextSyntheticPressId;
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
      final bytes = _buildWarmWoodPianoWav(
        frequency: frequency,
        durationMs: durationMs,
        volume: volume,
        velocity: velocity,
      );
      debugPrint('Generated WAV bytes length: ${bytes.length}');
      await player
          .play(BytesSource(bytes, mimeType: 'audio/wav'))
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
  Uint8List _buildWarmWoodPianoWav({
    required double frequency,
    required int durationMs,
    required double volume,
    required double velocity,
  }) {
    final totalSamples = (_sampleRate * durationMs / 1000).round();
    final pcmBytes = BytesBuilder(copy: false);

    // Higher keys naturally fade a little faster. Lower keys feel warmer.
    final keyPosition = ((frequency - 261.63) / (523.25 - 261.63)).clamp(0.0, 1.0);
    final mainDecay = 2.0 + keyPosition * 1.25;
    final bodyDecay = 0.9 + keyPosition * 0.65;
    final brightness = 0.72 + keyPosition * 0.22;

    for (var i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / totalSamples;

      // Fast hammer attack, then wood/string decay. The release fade prevents
      // clicks when the generated WAV ends.
      final attack = 1.0 - math.exp(-t * 420.0);
      final stringDecay = 0.74 * math.exp(-mainDecay * progress) +
          0.26 * math.exp(-bodyDecay * progress);
      final release = progress > 0.86 ? (1.0 - progress) / 0.14 : 1.0;
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
      final hammer = _hammerTransient(t, frequency, velocity);
      final body = _woodBodyResonance(t, frequency, keyPosition);

      final leftValue = _toInt16(
        _softClip((left + hammer * 0.55 + body) * envelope * volume),
      );
      final rightValue = _toInt16(
        _softClip((right + hammer * 0.45 + body) * envelope * volume),
      );

      pcmBytes
        ..addByte(leftValue & 0xff)
        ..addByte((leftValue >> 8) & 0xff)
        ..addByte(rightValue & 0xff)
        ..addByte((rightValue >> 8) & 0xff);
    }

    final pcmData = pcmBytes.takeBytes();
    return _wrapPcmAsWav(pcmData);
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
      sample += _harmonic(f, t, 2, 0.48 * brightness);
      sample += _harmonic(f, t, 3, 0.24 * brightness);
      sample += _harmonic(f, t, 4, 0.12 * brightness);
      sample += _harmonic(f, t, 5, 0.065 * brightness);
      sample += _harmonic(f, t, 6, 0.036 * brightness);
      sample += _harmonic(f, t, 8, 0.018 * brightness);
    }

    // Velocity changes timbre: harder notes are slightly brighter.
    final velocityBrightness = 0.88 + velocity * 0.18;
    return sample / detunes.length * velocityBrightness * 0.52;
  }

  double _harmonic(double baseFrequency, double t, int harmonic, double amount) {
    // Higher harmonics decay a little faster, reducing synthetic harshness.
    final harmonicDecay = math.exp(-t * harmonic * 0.62);
    return amount * harmonicDecay * math.sin(2 * math.pi * baseFrequency * harmonic * t);
  }

  double _hammerTransient(double t, double frequency, double velocity) {
    final transient = math.exp(-t * 95.0);
    final clickTone = math.sin(2 * math.pi * frequency * 7.0 * t);
    final woodyTap = math.sin(2 * math.pi * 1800.0 * t) * 0.35;
    final softNoise = _deterministicNoise(t) * 0.18;
    return transient * velocity * 0.13 * (clickTone + woodyTap + softNoise);
  }

  double _woodBodyResonance(double t, double frequency, double keyPosition) {
    // Subtle resonances give a small soundboard/body feeling.
    final bodyAmount = 0.026 * (1.0 - keyPosition * 0.35);
    final bodyDecay = math.exp(-t * 2.2);
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
    await _effectsPlayer.dispose();
  }
}
