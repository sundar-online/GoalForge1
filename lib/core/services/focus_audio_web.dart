// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import '../utils/logger.dart';

class FocusAudioPlatform {
  static final Map<String, String> _wavCache = {};

  static void playSound(String sound, double volume) {
    final soundKey = sound.toUpperCase();
    AppLogger.i('Playing Focus Sound: $soundKey at volume ${volume.toStringAsFixed(2)}');
    try {
      final vol = volume.clamp(0.0, 1.0);
      final dataUri = _getSoundDataUri(soundKey);
      final audio = html.AudioElement(dataUri);
      audio.volume = vol;
      audio.play().catchError((e) {
        AppLogger.w('Browser audio playback prevented: $e');
      });
    } catch (e, stack) {
      AppLogger.e('Error playing Web Audio sound: $soundKey', e, stack);
    }
  }

  static void previewSound(String sound, double volume) {
    playSound(sound, volume);
  }

  static String _getSoundDataUri(String soundKey) {
    if (_wavCache.containsKey(soundKey)) {
      return _wavCache[soundKey]!;
    }

    String uri;
    switch (soundKey) {
      case 'ZEN':
        uri = _generateZenWav();
        break;
      case 'CYBER':
        uri = _generateCyberWav();
        break;
      case 'BELL':
        uri = _generateBellWav();
        break;
      case 'ALARM':
      default:
        uri = _generateAlarmWav();
        break;
    }
    _wavCache[soundKey] = uri;
    return uri;
  }

  static String _generateZenWav() {
    return _createWavUri(
      durationSeconds: 2.0,
      sampleGenerator: (t) {
        final decay = math.exp(-2.5 * t);
        final tone1 = math.sin(2 * math.pi * 432.0 * t);
        final tone2 = math.sin(2 * math.pi * 528.0 * t);
        return 0.5 * (tone1 + tone2) * decay;
      },
    );
  }

  static String _generateCyberWav() {
    return _createWavUri(
      durationSeconds: 0.8,
      sampleGenerator: (t) {
        final freqs = [523.25, 659.25, 783.99, 1046.50];
        final noteIdx = (t / 0.2).floor().clamp(0, 3);
        final noteT = t % 0.2;
        final freq = freqs[noteIdx];
        final decay = math.exp(-12.0 * noteT);
        final phase = (t * freq) % 1.0;
        final tri = phase < 0.5 ? (4 * phase - 1) : (3 - 4 * phase);
        return 0.6 * tri * decay;
      },
    );
  }

  static String _generateBellWav() {
    return _createWavUri(
      durationSeconds: 2.5,
      sampleGenerator: (t) {
        final decay = math.exp(-2.0 * t);
        final f1 = math.sin(2 * math.pi * 587.33 * t);
        final f2 = math.sin(2 * math.pi * 1174.66 * t) * 0.5;
        final f3 = math.sin(2 * math.pi * 1761.99 * t) * 0.25;
        return 0.5 * (f1 + f2 + f3) * decay;
      },
    );
  }

  static String _generateAlarmWav() {
    return _createWavUri(
      durationSeconds: 1.0,
      sampleGenerator: (t) {
        final beepIdx = (t / 0.25).floor().clamp(0, 3);
        final beepT = t % 0.25;
        if (beepT > 0.18) return 0.0;
        final freq = beepIdx % 2 == 0 ? 880.0 : 1046.5;
        final sq = math.sin(2 * math.pi * freq * t) >= 0 ? 0.7 : -0.7;
        final env = math.exp(-4.0 * beepT);
        return sq * env;
      },
    );
  }

  static String _createWavUri({
    required double durationSeconds,
    required double Function(double t) sampleGenerator,
    int sampleRate = 22050,
  }) {
    final numSamples = (durationSeconds * sampleRate).toInt();
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    final bytes = ByteData(44 + dataSize);

    // RIFF header
    bytes.setUint8(0, 0x52); // 'R'
    bytes.setUint8(1, 0x49); // 'I'
    bytes.setUint8(2, 0x46); // 'F'
    bytes.setUint8(3, 0x46); // 'F'
    bytes.setUint32(4, fileSize, Endian.little);
    bytes.setUint8(8, 0x57); // 'W'
    bytes.setUint8(9, 0x41); // 'A'
    bytes.setUint8(10, 0x56); // 'V'
    bytes.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    bytes.setUint8(12, 0x66); // 'f'
    bytes.setUint8(13, 0x6d); // 'm'
    bytes.setUint8(14, 0x74); // 't'
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);

    // data subchunk
    bytes.setUint8(36, 0x64); // 'd'
    bytes.setUint8(37, 0x61); // 'a'
    bytes.setUint8(38, 0x74); // 't'
    bytes.setUint8(39, 0x61); // 'a'
    bytes.setUint32(40, dataSize, Endian.little);

    // Fill PCM samples
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final val = sampleGenerator(t).clamp(-1.0, 1.0);
      final intSample = (val * 32767).toInt().clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, intSample, Endian.little);
    }

    final base64Str = base64Encode(bytes.buffer.asUint8List());
    return 'data:audio/wav;base64,$base64Str';
  }
}
