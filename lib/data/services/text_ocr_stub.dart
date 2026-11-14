/// Web fallback for the on-device OCR service.
///
/// ML Kit has no web implementation, so photo translation is simply not
/// offered in browsers: [isSupported] stays false and the UI hides the entry
/// point instead of failing at runtime.
class TextOcr {
  static bool get isSupported => false;

  Future<String> recognizeText(String imagePath) async =>
      throw UnsupportedError('On-device OCR is unavailable on this platform.');

  Future<void> dispose() async {}
}
