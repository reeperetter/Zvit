import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> init() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize();
    return _isInitialized;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required String localeId,
    required Function(String text) onResult,
  }) async {
    final ready = await init();
    if (!ready) return;

    await _speech.listen(
      localeId: localeId,
      listenMode: ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
