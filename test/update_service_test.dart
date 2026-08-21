import 'package:flutter_test/flutter_test.dart';

import 'package:english_core_tap/core/constants.dart';
import 'package:english_core_tap/data/services/update_service.dart';

void main() {
  test('isNewer semver comparison', () {
    expect(UpdateService.isNewer('v1.0.11', '1.0.10'), isTrue);
    expect(UpdateService.isNewer('v2.0.0', '1.9.10'), isTrue);
    expect(UpdateService.isNewer('v1.0.10', '1.0.10'), isFalse,
        reason: 'same version must NOT prompt again (loop guard)');
    expect(UpdateService.isNewer('v1.0.9', '1.0.10'), isFalse);
    expect(UpdateService.isNewer('V1.1.0', '1.0.99'), isTrue);
    expect(UpdateService.isNewer('1.0', '1.0.0'), isFalse);
  });

  test('shipped version constant matches the release convention', () {
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(Constants.appVersion), isTrue,
        reason: 'appVersion must be plain X.Y.Z to compare with tags');
  });

  test('isTrustedReleaseUrl accepts only this repo release URLs', () {
    const repo = Constants.githubRepo;
    expect(
      UpdateService.isTrustedReleaseUrl(
          'https://github.com/$repo/releases/download/v1.0.16/app.apk'),
      isTrue,
    );
    expect(
      UpdateService.isTrustedReleaseUrl(
          'https://github.com/$repo/releases/tag/v1.0.16'),
      isTrue,
    );
    // Wrong repo.
    expect(
      UpdateService.isTrustedReleaseUrl(
          'https://github.com/evil/mirror/releases/download/v1/app.apk'),
      isFalse,
    );
    // Wrong scheme / host.
    expect(
      UpdateService.isTrustedReleaseUrl(
          'http://github.com/$repo/releases/download/v1/app.apk'),
      isFalse,
    );
    expect(
      UpdateService.isTrustedReleaseUrl(
          'https://evil.example.com/$repo/releases/download/v1/app.apk'),
      isFalse,
    );
    // Not a release path.
    expect(
      UpdateService.isTrustedReleaseUrl('https://github.com/$repo/wiki'),
      isFalse,
    );
    expect(UpdateService.isTrustedReleaseUrl('not a url'), isFalse);
    expect(UpdateService.isTrustedReleaseUrl(''), isFalse);
  });
}
