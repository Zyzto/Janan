import 'package:blood_pressure_app/features/settings/registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replay onboarding is visible in About and the flag is hidden', () {
    final registry = createAppSettingsRegistry();
    expect(
      registry.getVisibleSettingsInSection('about').map((s) => s.key),
      containsAll(['replay_onboarding', 'version']),
    );
    expect(onboardingCompletedSetting.visible, isFalse);
    expect(
      registry.settings.map((s) => s.key),
      containsAll(['onboarding_completed', 'replay_onboarding']),
    );
  });
}
