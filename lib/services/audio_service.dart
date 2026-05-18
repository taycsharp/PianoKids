import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../models/piano_note.dart';
import '../models/song.dart';

/// Audio service for Happy Piano Kids.
///
/// Audio strategy:
/// 1. Pre-generate and preload the full 88-key piano range for live keyboard.
/// 2. Play live keyboard notes as independent, fire-and-forget SoLoud voices.
/// 3. Keep song demo timing separate so rhythm/BPM playback remains stable.
///
/// Important: the generated tone is not a copyrighted sample or exact clone of
/// Steinway, Yamaha, or any other brand. It is a brand-inspired, synthetic,
/// wood-piano-like tone designed for a kid-friendly MVP.
class AudioService {
  AudioService() {
    _keyboardAudioReady = _prepareKeyboardAudioEngine();
    unawaited(_keyboardAudioReady);
  }

  final AudioPlayer _effectsPlayer = AudioPlayer();
  final Map<String, bool> _assetAvailabilityByNote = {};
  final Map<String, AudioSource> _keyboardSourcesByNoteName = {};
  late final Future<void> _keyboardAudioReady;
  bool _isKeyboardAudioReady = false;
  var _songDemoToken = 0;

  static const double _demoTempoMultiplier = 1.0;
  static const int _songGapMs = 45;
  static const Duration _audioStartTimeout = Duration(milliseconds: 900);
  static const Duration _soloudLoadTimeout = Duration(seconds: 8);

  static const int _sampleRate = 44100;
  static const int _channels = 2;
  static const int _bitsPerSample = 16;
  static const int _maxActiveKeyboardVoices = 48;

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

  Future<void> playNote(String note) async {
    await _playSongDemoNote(note, const Duration(milliseconds: 420));
  }

  /// Plays one short, naturally decaying keyboard note.
  ///
  /// This is intentionally fire-and-forget for the live keyboard MVP: every
  /// pointer down asks SoLoud to start a new independent voice from a preloaded
  /// source. Pointer up is handled by the widgets as a highlight-only event.
  void playKeyboardNote(String note) {
    final pianoNote = PianoNote.fromKeyboardLabel(note);
    if (pianoNote == null) {
      debugPrint('No piano registry note for keyboard input: $note');
      return;
    }

    debugPrint('Keyboard note triggered: ${pianoNote.name}');

    if (!_isKeyboardAudioReady || !SoLoud.instance.isInitialized) {
      debugPrint('Keyboard piano cache not ready for ${pianoNote.name}');
      return;
    }

    final source = _keyboardSourcesByNoteName[pianoNote.name];
    if (source == null) {
      debugPrint('No preloaded keyboard source for ${pianoNote.name}');
      return;
    }

    try {
      SoLoud.instance.play(source, volume: _keyboardVolumeFor(pianoNote));
      debugPrint('Soloud voice started: ${pianoNote.name}');
    } catch (error) {
      debugPrint('Keyboard piano note skipped for ${pianoNote.name}. Error: $error');
    }
  }

  /// Legacy API for non-keyboard callers. It now uses the same fire-and-forget
  /// decaying note model as the live keyboard.
  Future<void> startNote(String note) async {
    playKeyboardNote(note);
  }

  /// Legacy press-aware API kept for screens that still pass pointer IDs.
  /// Release is intentionally ignored so audio can decay naturally.
  Future<void> startNoteForPress({
    required String note,
    required int pressId,
  }) async {
    playKeyboardNote(note);
  }

  /// Release only affects UI highlight in the keyboard widgets; audio is not
  /// stopped for MVP live notes.
  Future<void> stopNoteForPress(int pressId) async {}

  /// Release only affects UI highlight in the keyboard widgets; audio is not
  /// stopped for MVP live notes.
  Future<void> stopNote(String note) async {}

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
    // Live keyboard notes are short, fire-and-forget SoLoud voices that decay
    // naturally. There is no held-key keyboard voice lifecycle to stop.
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

  Future<void> _prepareKeyboardAudioEngine() async {
    try {
      // Yield out of the service constructor before doing native engine startup
      // and the heavier WAV synthesis work. After this future completes, a
      // key press only asks SoLoud to play an already-loaded AudioSource.
      await Future<void>.delayed(Duration.zero);
      await _loadAssetManifest();

      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        await soloud.init().timeout(_soloudLoadTimeout);
      }
      soloud.setMaxActiveVoiceCount(_maxActiveKeyboardVoices);

      for (final pianoNote in PianoNote.standard88) {
        final bytes = _buildWarmWoodPianoWav(
          frequency: pianoNote.frequency,
          midiNumber: pianoNote.midiNumber,
          durationMs: _keyboardDurationFor(pianoNote),
          volume: _generationVolumeFor(pianoNote),
          velocity: 0.72,
        );
        final source = await soloud
            .loadMem(_keyboardToneFileName(pianoNote.name), bytes)
            .timeout(_soloudLoadTimeout);

        _keyboardSourcesByNoteName[pianoNote.name] = source;
      }

      _isKeyboardAudioReady = true;
      debugPrint('Piano cache ready: ${_keyboardSourcesByNoteName.length} notes');
    } catch (error) {
      _isKeyboardAudioReady = false;
      debugPrint('Keyboard audio engine unavailable. Error: $error');
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
    final pianoNote = PianoNote.fromKeyboardLabel(note);
    final debugNote = pianoNote?.name ?? _debugNoteName(note);
    if (pianoNote == null) {
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
          frequency: pianoNote.frequency,
          midiNumber: pianoNote.midiNumber,
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

  Future<void> _playGeneratedTone({
    required AudioPlayer player,
    required double frequency,
    int? midiNumber,
    required int durationMs,
    required double volume,
    required double velocity,
  }) async {
    try {
      await player.stop();
      final bytes = _buildWarmWoodPianoWav(
        frequency: frequency,
        midiNumber: midiNumber,
        durationMs: durationMs,
        volume: volume,
        velocity: velocity,
      );
      await player
          .play(BytesSource(bytes, mimeType: 'audio/wav'))
          .timeout(_audioStartTimeout);
    } catch (error) {
      // Audio should never block the child from using the app.
      debugPrint('Generated piano tone skipped. Error: $error');
    }
  }

  String _debugNoteName(String note) {
    final pianoNote = PianoNote.fromKeyboardLabel(note);
    if (pianoNote != null) return pianoNote.name;
    return note;
  }

  String _keyboardToneFileName(String noteName) {
    final safeNote = noteName
        .replaceAll('#', '_sharp')
        .replaceAll(' ', '_')
        .toLowerCase();
    return 'happy_piano_kids_$safeNote.wav';
  }

  int _keyboardDurationFor(PianoNote note) {
    if (note.midiNumber <= 47) return 1200; // A0-B2: warmer, longer decay.
    if (note.midiNumber >= 84) return 850; // C6-C8: bright but gentle.
    return 1000; // C3-B5: balanced live keyboard note.
  }

  double _generationVolumeFor(PianoNote note) {
    if (note.midiNumber <= 47) return 0.50;
    if (note.midiNumber >= 84) return 0.42;
    return 0.48;
  }

  double _keyboardVolumeFor(PianoNote note) {
    if (note.midiNumber <= 47) return 0.84;
    if (note.midiNumber >= 84) return 0.68;
    return 0.78;
  }

  /// Generates a short, warm acoustic-style piano WAV.
  ///
  /// The synthesis is intentionally lightweight but piano-like:
  /// - fast hammer attack
  /// - layered harmonics/string detune
  /// - natural decay
  /// - harmonic partials that decay faster at higher frequencies
  /// - a tiny hammer/noise transient
  /// - soft saturation instead of hard clipping
  /// - subtle stereo spread for a soundboard-like feeling
  Uint8List _buildWarmWoodPianoWav({
    required double frequency,
    int? midiNumber,
    required int durationMs,
    required double volume,
    required double velocity,
  }) {
    final totalSamples = (_sampleRate * durationMs / 1000).round();
    final pcmBytes = BytesBuilder(copy: false);

    final notePosition = _pianoRangePosition(frequency, midiNumber);
    final lowWarmth = 1.0 - notePosition;
    final highBrightness = notePosition;

    final mainDecay = 1.45 + highBrightness * 2.2;
    final bodyDecay = 0.68 + highBrightness * 1.12;
    final brightness = 0.56 + highBrightness * 0.44;
    final harmonicScale = 0.78 + highBrightness * 0.26;

    for (var i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / totalSamples;

      // Fast hammer attack, then wood/string decay. The release fade prevents
      // clicks when the generated WAV ends without needing a pointer-up stop.
      final attack = 1.0 - math.exp(-t * 440.0);
      final stringDecay = (0.76 + lowWarmth * 0.08) * math.exp(-mainDecay * progress) +
          (0.24 - lowWarmth * 0.04) * math.exp(-bodyDecay * progress);
      final releaseStart = notePosition > 0.72 ? 0.80 : 0.86;
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
        harmonicScale: harmonicScale,
        detuneDirection: -1,
      );
      final right = _pianoSample(
        t: t,
        frequency: frequency,
        velocity: velocity,
        brightness: brightness,
        harmonicScale: harmonicScale,
        detuneDirection: 1,
      );

      // Very short hammer transient adds acoustic touch but remains gentle.
      final hammer = _hammerTransient(t, frequency, velocity, notePosition);
      final body = _woodBodyResonance(t, frequency, notePosition);

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

  double _pianoRangePosition(double frequency, int? midiNumber) {
    final midi = midiNumber ??
        (PianoNote.a4Midi + 12 * math.log(frequency / PianoNote.a4Frequency) / math.ln2);
    return ((midi - PianoNote.lowestPianoMidi) /
            (PianoNote.highestPianoMidi - PianoNote.lowestPianoMidi))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _pianoSample({
    required double t,
    required double frequency,
    required double velocity,
    required double brightness,
    required double harmonicScale,
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
      sample += _harmonic(f, t, 2, 0.48 * brightness * harmonicScale);
      sample += _harmonic(f, t, 3, 0.24 * brightness * harmonicScale);
      sample += _harmonic(f, t, 4, 0.12 * brightness * harmonicScale);
      sample += _harmonic(f, t, 5, 0.060 * brightness * harmonicScale);
      sample += _harmonic(f, t, 6, 0.032 * brightness * harmonicScale);
      sample += _harmonic(f, t, 8, 0.014 * brightness * harmonicScale);
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

  double _hammerTransient(
    double t,
    double frequency,
    double velocity,
    double notePosition,
  ) {
    final transient = math.exp(-t * 95.0);
    final clickTone = math.sin(2 * math.pi * frequency * 7.0 * t);
    final highSoftener = 1.0 - notePosition * 0.35;
    final woodyTap = math.sin(2 * math.pi * 1800.0 * t) * 0.35 * highSoftener;
    final softNoise = _deterministicNoise(t) * 0.18 * highSoftener;
    return transient * velocity * 0.13 * (clickTone + woodyTap + softNoise);
  }

  double _woodBodyResonance(double t, double frequency, double notePosition) {
    // Subtle resonances give a small soundboard/body feeling. Low notes get a
    // little more body warmth; high notes stay shorter and less piercing.
    final lowWarmth = 1.0 - notePosition;
    final bodyAmount = 0.018 + lowWarmth * 0.020;
    final bodyDecay = math.exp(-t * (1.8 + notePosition * 1.0));
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
    for (final source in _keyboardSourcesByNoteName.values) {
      try {
        await SoLoud.instance.disposeSource(source);
      } catch (_) {
        // Audio cleanup should never break the app.
      }
    }
    _keyboardSourcesByNoteName.clear();
    await _effectsPlayer.dispose();
  }
}
