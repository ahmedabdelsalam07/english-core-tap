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
}
