import '../utils/logger.dart';

class FocusAudioPlatform {
  static void playSound(String sound, double volume) {
    AppLogger.i('[AudioStub] Playing sound $sound at volume $volume');
  }

  static void previewSound(String sound, double volume) {
    AppLogger.i('[AudioStub] Previewing sound $sound at volume $volume');
  }
}
