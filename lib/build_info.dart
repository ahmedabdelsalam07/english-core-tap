/// Build identity compiled into the app at build time.
///
/// The web deploy workflow passes `--dart-define=BUILD_SHA=...` and
/// `--dart-define=BUILD_TIME=...`. Local builds and non-web targets keep the
/// fallback values below.
class BuildInfo {
  const BuildInfo._();

  static const String sha =
      String.fromEnvironment('BUILD_SHA', defaultValue: 'dev');
  static const String builtAt =
      String.fromEnvironment('BUILD_TIME', defaultValue: 'local build');

  /// One-line label, e.g. `bdf859e . 2026-11-14 16:22 UTC`.
  static const String label = '$sha \u00b7 $builtAt';
}
