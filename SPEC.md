The failure is NOT caused by the repository rename.

The IPA was successfully built and signed.

The new archive version validation is resolving the archive path incorrectly.

Fastlane runs from ios/, and build_app uses:

archive_path: "../build/ios/archive/Runner.xcarchive"

Therefore the real archive is:

<repo>/build/ios/archive/Runner.xcarchive

But the validation currently looks under:

<repo>/ios/build/ios/archive/Runner.xcarchive

Fix the archive validation path.

From ios/fastlane/Fastfile __dir__, use:

../../build/ios/archive/Runner.xcarchive

not:

../build/ios/archive/Runner.xcarchive

Prefer defining one absolute ARCHIVE_PATH constant and reuse it in both build_app and archive validation so paths cannot diverge.

Do NOT modify:
- Fastlane Match
- signing
- certificates
- provisioning profiles
- apple-signing
- App Store Connect authentication

After fixing the path, validate:
CFBundleShortVersionString = 2.0.1
CFBundleVersion = 72

Then continue upload_to_testflight.