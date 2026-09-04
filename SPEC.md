Fix iOS build-number propagation only.

Current problem:
- pubspec/build artifact name is 2.0.1+70
- App Store Connect still receives CFBundleVersion 68
- ios/Runner/Info.plist uses $(CURRENT_PROJECT_VERSION)
- Runner.xcodeproj currently hardcodes CURRENT_PROJECT_VERSION = 68

Required:
1. In ios/Runner.xcodeproj/project.pbxproj, replace hardcoded Runner
   CURRENT_PROJECT_VERSION values with:
   "$(FLUTTER_BUILD_NUMBER)"

2. Preserve:
   MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)"

3. Do this for all relevant Runner build configurations
   (Debug/Profile/Release), not just Release.

4. Do not modify Match, certificates, profiles, apple-signing,
   signing secrets, or TestFlight authentication.

5. Before upload_to_testflight, validate the built archive:
   CFBundleShortVersionString must equal pubspec version name.
   CFBundleVersion must equal pubspec build number.

6. Fail before upload if archive CFBundleVersion differs from
   the pubspec build number.

Expected for current release:
CFBundleShortVersionString = 2.0.1
CFBundleVersion = 70