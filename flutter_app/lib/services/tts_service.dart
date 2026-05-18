import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService() {
    init();
  }

  Future<void> init() async {
    try {
      // Пробуем установить казахский язык
      bool kkAvailable = await _flutterTts.isLanguageAvailable('kk-KZ');

      if (kkAvailable) {
        await _flutterTts.setLanguage('kk-KZ');
        print("✅ Казахский язык установлен");
      } else {
        // Если казахского нет, используем русский
        await _flutterTts.setLanguage('ru-RU');
        print("⚠️ Казахский не найден, использую русский");
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _isInitialized = true;
      print("✅ TTS сервис инициализирован");
    } catch (e) {
      print("❌ Ошибка инициализации TTS: $e");
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      print("🔊 Говорим: ${text.substring(0, text.length > 50 ? 50 : text.length)}...");
      await _flutterTts.speak(text);
    } catch (e) {
      print("❌ Ошибка воспроизведения: $e");
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      print("⏸ Пауза");
    } catch (e) {
      print("❌ Ошибка паузы: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      print("⏹ Остановлено");
    } catch (e) {
      print("❌ Ошибка остановки: $e");
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}