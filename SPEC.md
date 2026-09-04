# SPEC: MIGRATE EDU-TECH iOS TESTFLIGHT SIGNING TO FASTLANE MATCH

Repository:
https://github.com/NguyenMinhDuc163/Edu-Tech

Branch:
main

Signing repository:
https://github.com/NguyenMinhDuc163/apple-signing

==================================================
1. MỤC TIÊU
==================================================

Migrate ONLY iOS TestFlight code signing của Edu-Tech từ cách cũ:

GitHub Secrets:
- IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64
- IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
- IOS_APPSTORE_PROVISIONING_PROFILE_BASE64

→ decode P12/profile
→ create keychain
→ security import
→ build

sang:

Fastlane Match
→ private repo NguyenMinhDuc163/apple-signing
→ Apple Distribution certificate
→ App Store provisioning profile
→ temporary CI keychain
→ build
→ TestFlight

Không viết lại CI từ đầu.

Project hiện tại đã build/upload iOS TestFlight thành công trước migration.
Phải giữ tối đa flow đang hoạt động và chỉ thay signing layer.

==================================================
2. THÔNG TIN SIGNING
==================================================

Bundle ID:

com.nguyenduc.edtech

Apple Team ID:

Q236Z72BGN

Signing repo:

https://github.com/NguyenMinhDuc163/apple-signing.git

Signing repo đã có:

certs/distribution/
  Certificates.cer
  Certificates.p12

profiles/appstore/
  AppStore_com.nguyenduc.edtech.mobileprovision

KHÔNG:
- import lại certificate
- generate certificate mới
- renew certificate
- renew provisioning profile
- đổi bundle ID
- sửa apple-signing repo

Chỉ consume existing assets bằng Match readonly.

==================================================
3. CÁC FILE CHÍNH CẦN SỬA
==================================================

Bắt buộc:

ios/fastlane/Matchfile                 # add
ios/fastlane/Fastfile                  # modify
.github/workflows/reusable-ios-testflight.yml

Nên update documentation:

ios/fastlane/Appfile
ios/fastlane/.env.example
ios/fastlane/README.md

Và search toàn repository để sửa documentation/config còn nhắc tới signing secrets cũ.

KHÔNG sửa nếu không thật sự cần:

.github/workflows/mobile-store-release.yml
.github/workflows/reusable-android-google-play.yml
android/
pubspec version bump logic
Flutter setup
CocoaPods flow
artifact upload
Xcode project
application source code

mobile-store-release.yml hiện dùng:

secrets: inherit

và flow bump version → reusable iOS workflow đã hoạt động.
Giữ nguyên architecture đó.

==================================================
4. MATCHFILE
==================================================

Add:

ios/fastlane/Matchfile

Nội dung:

git_url(ENV.fetch("MATCH_GIT_URL"))
storage_mode("git")
git_branch("main")

app_identifier([
  "com.nguyenduc.edtech"
])

type("appstore")

team_id(ENV["IOS_TEAM_ID"]) unless ENV["IOS_TEAM_ID"].to_s.strip.empty?

Không hard-code token/password.

Không dùng readonly trong Matchfile.
readonly phải được đặt rõ trong Fastfile lane.

==================================================
5. FASTFILE - NGUYÊN TẮC
==================================================

Giữ nguyên:

- pubspec_version
- flutter_command
- pod install
- build_app
- workspace Runner.xcworkspace
- scheme Runner
- Release configuration
- archive path
- IPA output path/name
- upload_to_testflight
- version/build logic

Chỉ migrate signing.

==================================================
6. FASTFILE - setup_ci
==================================================

Trong lane:

ios beta

PHẢI gọi:

setup_ci

trước Match.

Ví dụ architecture:

lane :beta do
  setup_ci

  api_key = app_store_connect_api_key(...)

  match(...)

  ...

  build

  upload_to_testflight(...)
end

Không bỏ setup_ci.

LÝ DO QUAN TRỌNG:

Ở migration project trước, Match có thể decrypt/install signing asset nhưng build vẫn gặp vấn đề signing nếu không setup CI keychain đúng cách.

setup_ci phải chịu trách nhiệm tạo temporary keychain cho GitHub Actions.

KHÔNG tự tạo thêm manual signing keychain trong workflow.

==================================================
7. FASTFILE - APP STORE CONNECT API KEY
==================================================

Giữ cách auth bằng API key:

api_key = app_store_connect_api_key(
  key_id: ENV.fetch("APP_STORE_CONNECT_KEY_ID"),
  issuer_id: ENV.fetch("APP_STORE_CONNECT_ISSUER_ID"),
  key_filepath: ENV.fetch("APP_STORE_CONNECT_API_KEY_KEY_FILEPATH")
)

Không dùng:

Apple ID/password
FASTLANE_USER
FASTLANE_PASSWORD
interactive login

==================================================
8. FASTFILE - MATCH
==================================================

Trong lane ios beta thêm:

match(
  type: "appstore",
  platform: "ios",
  app_identifier: APP_IDENTIFIER,
  readonly: true,
  api_key: api_key
)

BẮT BUỘC:

readonly: true

Routine project CI chỉ được READ signing repo.

Không được dùng:

readonly: false
force: true
match nuke
revoke
generate new certificate

Việc maintain/create/renew signing asset được xử lý riêng trong
apple-signing maintenance workflow.

==================================================
9. LẤY PROVISIONING PROFILE TỪ MATCH
==================================================

Sau match, lấy mapping từ:

Actions.lane_context[
  SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING
]

Validate rằng mapping chứa:

com.nguyenduc.edtech

Ví dụ helper:

def match_provisioning_profile_name!
  profiles =
    Actions.lane_context[
      SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING
    ]

  unless profiles.is_a?(Hash)
    UI.user_error!(
      "Fastlane Match did not provide provisioning profile mapping."
    )
  end

  profile_name =
    profiles[APP_IDENTIFIER].to_s.strip

  if profile_name.empty?
    UI.user_error!(
      "Fastlane Match did not provide an App Store profile for #{APP_IDENTIFIER}."
    )
  end

  profile_name
end

Sau match:

profile_name = match_provisioning_profile_name!
ENV["IOS_PROVISIONING_PROFILE_NAME"] = profile_name

Sau đó reuse build logic hiện tại.

Mục tiêu là tận dụng code hiện có:

configure_ci_code_signing
build_export_options
build

Không cần rewrite build_app nếu không cần.

==================================================
10. SIGNING PHẢI VẪN MANUAL KHI BUILD
==================================================

Khi Match cung cấp profile name, Release build phải tiếp tục sử dụng:

Apple Distribution

và provisioning profile do Match trả về.

Existing:

configure_ci_code_signing

có thể giữ nguyên.

Expected:

use_automatic_signing: false
code_sign_identity: "Apple Distribution"
profile_name: Match profile name

Export options phải dùng:

signingStyle: "manual"

và:

provisioningProfiles:
  com.nguyenduc.edtech => Match profile name

Không quay về automatic signing cho CI TestFlight sau khi Match đã cài profile.

==================================================
11. WORKFLOW SECRETS - REMOVE OLD SIGNING INPUTS
==================================================

Trong:

.github/workflows/reusable-ios-testflight.yml

xóa khỏi workflow_call.secrets:

IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64
IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
IOS_APPSTORE_PROVISIONING_PROFILE_BASE64

Thêm:

IOS_TEAM_ID
MATCH_GIT_URL
MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION

Giữ:

APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8

==================================================
12. WORKFLOW JOB ENV
==================================================

Job iOS cần expose:

APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID

IOS_TEAM_ID

MATCH_GIT_URL
MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION

FASTLANE_SKIP_UPDATE_CHECK="1"
FASTLANE_HIDE_CHANGELOG="1"

Không expose raw old P12/profile secrets.

==================================================
13. VALIDATE REQUIRED SECRETS
==================================================

Validate đúng 7 Apple secrets:

APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8

IOS_TEAM_ID

MATCH_GIT_URL
MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION

Không validate:

IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64
IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
IOS_APPSTORE_PROVISIONING_PROFILE_BASE64

==================================================
14. XÓA MANUAL SIGNING STEP
==================================================

Xóa toàn bộ step hiện tại:

Install Apple signing assets

Bao gồm toàn bộ logic:

- base64 decode P12
- base64 decode mobileprovision
- create app-signing.keychain-db
- uuidgen keychain password
- security create-keychain
- security unlock-keychain
- security import P12
- security set-key-partition-list
- security list-keychains
- security cms profile
- copy mobileprovision vào ~/Library/MobileDevice/Provisioning Profiles
- export IOS_PROVISIONING_PROFILE_NAME từ profile manual

Sau migration không được còn manual security import signing certificate.

Match + setup_ci chịu trách nhiệm việc này.

==================================================
15. APP STORE CONNECT P8
==================================================

Giữ việc tạo:

$RUNNER_TEMP/AuthKey.p8

Nhưng dùng env thay vì interpolate secret trực tiếp trong shell.

Preferred:

env:
  APP_STORE_CONNECT_API_KEY_P8: ${{ secrets.APP_STORE_CONNECT_API_KEY_P8 }}

run:

key_path="$RUNNER_TEMP/AuthKey.p8"

printf '%s' "$APP_STORE_CONNECT_API_KEY_P8" > "$key_path"

chmod 600 "$key_path"

echo \
  "APP_STORE_CONNECT_API_KEY_KEY_FILEPATH=$key_path" \
  >> "$GITHUB_ENV"

Validate PEM:

BEGIN PRIVATE KEY
END PRIVATE KEY

Không dùng:

echo "$APP_STORE_CONNECT_API_KEY_P8"

Không print P8.

Add cleanup cuối workflow:

- name: Cleanup App Store Connect API key
  if: always()
  shell: bash
  run: rm -f "$RUNNER_TEMP/AuthKey.p8"

==================================================
16. GITHUB AUTH CHO APPLE-SIGNING
==================================================

Edu-Tech và apple-signing là 2 repository khác nhau.

KHÔNG dùng github.token/GITHUB_TOKEN của Edu-Tech để assume rằng nó đọc được apple-signing.

Dùng:

MATCH_GIT_BASIC_AUTHORIZATION

đã lưu trong repository secrets.

Nó phải là Base64 của:

NguyenMinhDuc163:PAT

PAT dùng cho normal CI:

- Fine-grained PAT
- chỉ access NguyenMinhDuc163/apple-signing
- Contents: Read-only

KHÔNG cần write access.

MATCH_GIT_BASIC_AUTHORIZATION không phải raw PAT.

MATCH_GIT_URL:

https://github.com/NguyenMinhDuc163/apple-signing.git

==================================================
17. MATCH_PASSWORD - CẢNH BÁO LỖI ĐÃ TỪNG GẶP
==================================================

MATCH_PASSWORD là password dùng encrypt/decrypt Match repository.

Nó KHÔNG phải:

- password Apple ID
- P12 password
- PAT
- App Store Connect key

Không trim/chỉnh sửa giá trị.

Không tự generate password mới.

Nếu CI báo decrypt error:

KHÔNG:
- re-import cert
- regenerate cert
- nuke repo

Trước tiên phải nghi ngờ MATCH_PASSWORD mismatch.

Đã từng gặp trường hợp giá trị thực tế và GitHub Secret khác số byte.

Nếu cần debug trên môi trường có value:

printf '%s' "$MATCH_PASSWORD" | wc -c

Không log nội dung password.

==================================================
18. P12 - CẢNH BÁO LỖI ĐÃ TỪNG GẶP
==================================================

Không tạo secret P12 password mới.

Không import P12 từ Edu-Tech.

P12 đã nằm encrypted trong:

apple-signing/certs/distribution/

Match xử lý certificate/private key.

Đừng thêm:

IOS_DISTRIBUTION_CERTIFICATE_PASSWORD

trở lại chỉ vì security import gặp vấn đề.

Sau migration không còn security import P12 thủ công.

==================================================
19. KEYCHAIN - CẢNH BÁO
==================================================

Không tự đoán path của Fastlane temporary keychain.

Không tạo code kiểu:

~/Library/Keychains/fastlane_tmp_keychain

rồi tự escape/path transform.

Project trước đã từng gặp lỗi vì "~" bị xử lý thành literal path và security không tìm thấy identity.

Với Edu-Tech iOS:

setup_ci
+
match

phải quản lý keychain.

Không cần custom keychain path.

==================================================
20. BUNDLER - CẢNH BÁO
==================================================

Hiện ios/Gemfile.lock đã lock:

fastlane 2.236.1

Không update dependency chỉ để thực hiện migration.

Không chạy:

bundle update

Không regenerate Gemfile.lock nếu không cần.

Không đổi Ruby/Fastlane version nếu migration không yêu cầu.

Workflow hiện dùng Ruby 4.0 và Fastlane hiện tại đã chạy được trước migration.

Giữ nguyên Ruby setup để giảm phạm vi thay đổi.

Nếu agent quyết định sửa Gemfile/Gemfile.lock thì phải có lý do cụ thể.

Đã từng gặp Bundler frozen/checksum issue ở migration trước, do đó tránh thay lockfile không cần thiết.

==================================================
21. APPFILE
==================================================

Hiện Appfile có:

apple_id("ngminhduc1603@icloud.com")

Bỏ dòng này.

Giữ:

app_identifier("com.nguyenduc.edtech")
team_id("Q236Z72BGN")

Lý do:

CI mới dùng App Store Connect API key.
Không cần phụ thuộc Apple ID cá nhân.

Không thay bằng Apple ID khác.

==================================================
22. ROOT RELEASE WORKFLOW
==================================================

Không rewrite:

.github/workflows/mobile-store-release.yml

Hiện flow:

workflow_dispatch / push
→ resolve release config
→ bump pubspec build number
→ commit [skip ci]
→ reusable-ios-testflight.yml
→ secrets: inherit

đã hoạt động.

Giữ nguyên.

Chỉ reusable iOS workflow cần migration signing.

==================================================
23. EXISTING VERSIONING
==================================================

Không thay:

pubspec.yaml version
build number increment logic
commit version bump
commit_sha handoff
artifact names

Migration signing không được thay đổi release/version behavior.

==================================================
24. DOCUMENTATION CLEANUP
==================================================

Update:

ios/fastlane/.env.example
ios/fastlane/README.md

Và search toàn repository cho:

IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64
IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
IOS_APPSTORE_PROVISIONING_PROFILE_BASE64

Các docs/skill files đang mô tả signing cũ cũng phải update để agent sau không khôi phục cách P12 base64 cũ.

Sau migration documentation phải nói required iOS CI secrets là:

APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8

IOS_TEAM_ID

MATCH_GIT_URL
MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION

Không sửa docs Android không liên quan.

==================================================
25. SECRETS KHÔNG ĐƯỢC XÓA TỰ ĐỘNG
==================================================

Agent KHÔNG được delete GitHub Secrets.

Ba secret cũ:

IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64
IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
IOS_APPSTORE_PROVISIONING_PROFILE_BASE64

chỉ được user xóa SAU KHI TestFlight Match build thành công.

==================================================
26. SECURITY RULES
==================================================

Tuyệt đối không:

match nuke
readonly: false
force: true
revoke certificate
create certificate
renew certificate
regenerate profile
modify apple-signing
commit decrypted signing assets
commit p8
commit PAT
print secrets
print MATCH_PASSWORD
print MATCH_GIT_BASIC_AUTHORIZATION

Routine Edu-Tech CI luôn:

readonly: true

==================================================
27. PRE-MIGRATION ASSUMPTIONS
==================================================

Signing assets đã tồn tại:

Apple Distribution
+
AppStore_com.nguyenduc.edtech.mobileprovision

Agent không cần tạo chúng.

Nếu Match báo không tìm thấy asset:

STOP.

Không tự tạo asset mới.

Report lỗi để kiểm tra:

MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION
MATCH_GIT_URL
bundle id
profile availability

==================================================
28. EXPECTED FINAL FASTLANE FLOW
==================================================

Expected:

GitHub macOS runner
        ↓
Checkout bumped commit
        ↓
Flutter setup
        ↓
Ruby/Bundler setup
        ↓
bundle exec fastlane ios beta
        ↓
setup_ci
        ↓
ASC API key
        ↓
Match appstore readonly
        ↓
clone private apple-signing
        ↓
decrypt with MATCH_PASSWORD
        ↓
install Apple Distribution + private key
        ↓
install com.nguyenduc.edtech App Store profile
        ↓
obtain Match profile mapping
        ↓
configure Runner Release manual signing
        ↓
build_app
        ↓
IPA
        ↓
upload_to_testflight

==================================================
29. REQUIRED GITHUB SECRETS AFTER MIGRATION
==================================================

Edu-Tech iOS signing/release requires:

APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8

IOS_TEAM_ID

MATCH_GIT_URL
MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION

The Match values can be the same values already proven in nro-unity,
because both projects use the same Apple Team and same apple-signing repo.

Do not copy old P12/profile secrets into the new design.

==================================================
30. TEST / VALIDATION BEFORE PUSH
==================================================

Agent phải inspect diff và chạy những validation không release được phép trong environment.

At minimum:

cd ios
bundle check

bundle exec fastlane lanes

Ruby syntax:

ruby -c fastlane/Fastfile

Verify Matchfile syntax where possible.

Validate GitHub Actions YAML.

Search:

grep -R \
  "IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64\|IOS_DISTRIBUTION_CERTIFICATE_PASSWORD\|IOS_APPSTORE_PROVISIONING_PROFILE_BASE64" \
  . \
  --exclude-dir=.git

Expected:

Không còn reference trong active workflow/Fastlane/docs sau cleanup.

Nếu có historical/archive file cần giữ thì report rõ, không âm thầm bỏ qua.

Không trigger TestFlight từ agent nếu user chưa yêu cầu.

==================================================
31. USER TEST SAU KHI MERGE/PUSH
==================================================

Trước khi test Edu-Tech, có thể verify signing repo bằng:

Apple Signing Maintenance

mode:
verify

platform:
ios

type:
appstore

bundle_id:
com.nguyenduc.edtech

force_profile_renewal:
false

confirm_write:
false

Nếu verify xanh, test Edu-Tech:

Actions
→ Mobile Store Release
→ Run workflow

run_ios:
true

run_android:
false

Expected:

- version bump thành công
- reusable iOS workflow chạy
- Match successfully decrypts repo
- Match installs distribution certificate
- Match installs edtech App Store profile
- archive succeeds
- export IPA succeeds
- upload TestFlight succeeds

==================================================
32. THẾ NÀO LÀ MIGRATION THÀNH CÔNG
==================================================

Migration chỉ được coi là hoàn tất khi GitHub Actions TestFlight build thực tế thành công.

Không coi:

bundle exec fastlane lanes success

hoặc:

Match decrypt success

là full end-to-end success.

Phải có:

Archive succeeded
+
IPA export succeeded
+
TestFlight upload succeeded

==================================================
33. SAU KHI TESTFLIGHT THÀNH CÔNG
==================================================

User có thể xóa 3 GitHub Actions secrets cũ:

IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64
IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
IOS_APPSTORE_PROVISIONING_PROFILE_BASE64

Giữ:

APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8

IOS_TEAM_ID

MATCH_GIT_URL
MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION

==================================================
34. ACCEPTANCE CRITERIA
==================================================

Hoàn thành khi:

1. ios/fastlane/Matchfile tồn tại.

2. Matchfile trỏ tới MATCH_GIT_URL và branch main.

3. Bundle ID vẫn là:
   com.nguyenduc.edtech

4. Team vẫn là:
   Q236Z72BGN

5. ios beta gọi setup_ci.

6. ios beta gọi Match:
   type appstore
   platform ios
   readonly true

7. Provisioning profile lấy từ Match mapping.

8. Không còn manual P12/profile install trong reusable-ios-testflight.yml.

9. Không còn security import P12.

10. Không còn tạo custom signing keychain.

11. ASC API key vẫn được dùng để upload TestFlight.

12. mobile-store-release.yml architecture không bị rewrite.

13. Android flow không thay đổi.

14. pubspec version bump không thay đổi.

15. Appfile không còn Apple ID cá nhân.

16. Không sửa apple-signing.

17. Không create/revoke/renew Apple signing asset.

18. Existing three old signing secrets chưa bị agent delete.

19. Documentation đã chuyển sang Match secrets.

20. Agent report đầy đủ validation kết quả.

==================================================
35. OUTPUT AGENT PHẢI TRẢ VỀ
==================================================

Sau khi implement, report ngắn:

Changed files:
- ...

Signing flow:
old → new

Added required secrets:
- IOS_TEAM_ID
- MATCH_GIT_URL
- MATCH_PASSWORD
- MATCH_GIT_BASIC_AUTHORIZATION

Old secrets no longer referenced by code:
- IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64
- IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
- IOS_APPSTORE_PROVISIONING_PROFILE_BASE64

Validation:
- bundle check: ...
- fastlane lanes: ...
- Ruby syntax: ...
- YAML: ...
- old secret grep: ...

Explicit confirmations:
- apple-signing was NOT modified
- no certificate was generated
- no certificate/profile was revoked
- match nuke was NOT run
- maintain/readonly:false was NOT run
- TestFlight was NOT triggered unless explicitly requested