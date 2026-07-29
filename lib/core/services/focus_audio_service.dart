import 'focus_audio_stub.dart'
    if (dart.library.html) 'focus_audio_web.dart';

class FocusAudioService {
  void playAlertSound(String sound, double volume) {
    FocusAudioPlatform.playSound(sound, volume);
  }

  void previewSound(String sound, double volume) {
    FocusAudioPlatform.previewSound(sound, volume);
  }
}
