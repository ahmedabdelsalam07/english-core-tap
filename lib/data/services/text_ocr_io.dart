import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR through ML Kit — Android and iOS only.
///
/// Text in this app is either English or Arabic, and ML Kit recognises one
/// script per model, so the photo is read with the Latin model first and the
/// Arabic model only when that pass finds nothing.
class TextOcr {
  static bool get isSupported => true;

  TextRecognizer? _latin;
  TextRecognizer? _arabic;

  Future<String> recognizeText(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);

    final latin = _latin ??= TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    final latinText = (await latin.processImage(input)).text.trim();
    if (latinText.isNotEmpty) return latinText;

    final arabic = _arabic ??= TextRecognizer(
      script: TextRecognitionScript.arabic,
    );
    return (await arabic.processImage(input)).text.trim();
  }

  Future<void> dispose() async {
    await _latin?.close();
    await _arabic?.close();
    _latin = null;
    _arabic = null;
  }
}
