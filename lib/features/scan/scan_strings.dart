import 'package:flutter/widgets.dart';

/// Copy for the photo-translation feature.
///
/// These strings stay next to the feature instead of going into the shared ARB
/// files: the generated localisation sources are committed to this repository,
/// and adding ARB keys without regenerating them would leave the checked-in
/// generated code out of sync with its source.
class ScanStrings {
  final bool _ar;
  const ScanStrings._(this._ar);

  static ScanStrings of(BuildContext context) =>
      ScanStrings._(Localizations.localeOf(context).languageCode == 'ar');

  /// Short label for the tool button on the home input card.
  String get label => _ar ? 'صورة' : 'Photo';

  String get title => _ar ? 'ترجمة صورة' : 'Translate a photo';

  String get hint => _ar
      ? 'التقط صورة لنص إنجليزي أو عربي، وسنقرأ الكلمات من الصورة ثم نترجمها.'
      : 'Capture a photo of English or Arabic text; we read the words from the image and translate them.';

  String get camera => _ar ? 'الكاميرا' : 'Camera';

  String get gallery => _ar ? 'المعرض' : 'Gallery';

  String get reading => _ar ? 'جارٍ قراءة الصورة…' : 'Reading the image…';

  String get empty => _ar
      ? 'لم نجد نصًا واضحًا في الصورة. جرّب صورة أوضح أو إضاءة أفضل.'
      : 'No clear text found in that photo. Try a sharper photo or better lighting.';

  String get failed => _ar
      ? 'تعذّرت قراءة الصورة. حاول مرة أخرى.'
      : 'Could not read that image. Please try again.';
}
