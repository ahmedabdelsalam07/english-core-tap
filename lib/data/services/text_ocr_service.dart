/// On-device OCR entry point for photo translation.
///
/// The ML Kit engine only exists for Android and iOS, so the concrete
/// implementation is selected at compile time: browsers get the stub, which
/// reports the feature as unsupported instead of pulling in a plugin that
/// cannot run there.
export 'text_ocr_stub.dart' if (dart.library.io) 'text_ocr_io.dart';
