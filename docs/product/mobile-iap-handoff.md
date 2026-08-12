# Mobile IAP Handoff

Last updated: 2026-08-12

Tai lieu nay la diem ban giao cho agent tiep tuc trien khai va kiem thu IAP tren
Flutter cho Android va iOS. Khong ghi secret, private key, service-account JSON
hoac token dang nhap vao tai lieu.

## 1. Tai lieu nguon

- `SPEC.md`: nghiep vu va contract Mobile IAP day du.
- `docs/product/revenuecat-store-setup.md`: cach cau hinh credentials, Apple,
  Google Play, Pub/Sub va RevenueCat.
- Backend `Edtech-BE/spec.md`: contract va quy tac cap quyen phia server.
- Backend `Edtech-BE/IAP_DATABASE_GUIDE.md`: cac truong du lieu de hien thi va
  mo ban mot khoa hoc.

Khi tai lieu mau thuan, uu tien code/backend contract hien tai, sau do cap nhat
lai tai lieu bi cu.

## 2. Nguyen tac kien truc

1. Google Play/App Store xu ly thanh toan tren mobile.
2. RevenueCat ket noi Store, xac minh giao dich va phat webhook.
3. Backend la nguon su that duy nhat ve quyen hoc.
4. Flutter khong tu mo khoa hoc chi dua vao `CustomerInfo` hoac callback mua
   thanh cong.
5. Sau purchase/restore, Flutter goi backend sync va chi mo khoa khi backend tra
   `accessLevel = FULL`.
6. VNPay chi dung cho web va khong bi thay the boi IAP.
7. Gia mobile lay tu `StoreProduct.priceString`; `courses.price` khong duoc dung
   lam so tien thu tren Store.

## 3. Identifier hien tai

Identifiers khong phai secret, nhung phai trung tuyet doi giua Store,
RevenueCat va backend:

```text
Course:             28
Product ID:         edtech.course.28.lifetime
Purchase option:    lifetime
Entitlement ID:     course_28_access
Product type:       one-time / non-consumable
Android package:    com.nguyenduc.edtech.ed_tech
iOS bundle ID:      com.nguyenduc.edtech
Android test price: 10,000 VND
```

Khong doi Product ID sau khi product da duoc tao hoac co giao dich.

## 4. Trang thai trien khai

### Flutter

- Da them `purchases_flutter: ^10.8.0`.
- Da cau hinh public SDK key rieng cho Android va iOS qua Envied.
- `ApiPath.baseUrl` dang doc `_ApiPath.baseUrl`, khong hard-code IP local.
- `env/.env.dev` la nguon generate cho `api_path.g.dart`.
- Android main manifest da khai bao `com.android.vending.BILLING`.
- Android merged manifest co `com.google.android.gms.permission.AD_ID` do app
  dung Google Mobile Ads.
- Release hien tai la `2.0.0+72`; xem ket qua build moi nhat trong working tree
  thay vi dung lai artifact `2.0.0+71`.
- Purchase, restore, sync, pending va polling status da duoc implement.
- Nut `Mua ngay` khong doi thanh noi dung ky thuat trong luc tai product. Man
  xac nhan tu tai StoreProduct va hien nut thanh toan dung ten Store hien tai.
- Khi payment sheet lam app `inactive`, man xac nhan van duoc giu phia sau.
  Khi app that su `paused`, privacy overlay van che noi dung.

### Android external configuration

- RevenueCat Android app va Google service-account validation da cau hinh.
- Google RTDN Pub/Sub da connected va da tung nhan test notification.
- One-time product duoc khai bao voi ID
  `edtech.course.28.lifetime`, purchase option `lifetime`, loai `Buy`, digital
  content va gia test 10,000 VND.
- User bao da import product va attach entitlement trong RevenueCat; agent tiep
  theo phai kiem tra lai tren dashboard thay vi coi purchase end-to-end da pass.
- Purchase end-to-end chua duoc xac nhan. Lan kiem tra gan nhat Store tra
  `PRODUCT_NOT_FOUND` vi app tren thiet bi la ban `flutter run` co
  `installer=null`, khong phai ban cai tu Google Play Internal testing.

### iOS external configuration

- RevenueCat Apple app, App Store In-App Purchase key va App Store Connect API
  key da duoc cau hinh.
- Xcode Runner da khai bao In-App Purchase capability. Podfile, Xcode project
  va Flutter AppFramework deu dung deployment target iOS 15.0.
- Apple product cho course 28 va sandbox purchase chua duoc xac nhan hoan tat.
- Can tao non-consumable product cung identifier, import vao RevenueCat va
  attach vao `course_28_access` truoc khi test.

### Backend

- Backend IAP implementation nam trong commit `34d75ca`.
- Production migration runner nam trong commit `a7fc011`.
- Feature flag IAP doc database moi lan nam trong commit `1493e9d`.
- User da deploy code backend moi len production. Agent phai xac minh schema,
  course mapping, feature flags va webhook tren moi truong dich; khong suy dien
  chung da dung chi tu viec deploy thanh cong.

## 5. File code quan trong

```text
lib/modules/iap/service/iap_platform.dart
lib/modules/iap/service/revenuecat_service.dart
lib/modules/iap/repository/iap_repository.dart
lib/modules/iap/model/iap_models.dart
lib/modules/iap/bloc/iap_cubit.dart
lib/modules/iap/bloc/iap_state.dart
lib/modules/course/screen/course_detail_screen.dart
lib/modules/course/model/detail_course.dart
lib/modules/payment/screen/order_confirmation_screen.dart
lib/core/constants/api_path.dart
lib/core/constants/api_path.g.dart
android/app/src/main/AndroidManifest.xml
pubspec.yaml
```

## 6. API mobile dang su dung

```text
GET  /api/mobile-iap/config?platform=ANDROID|IOS
POST /api/mobile-iap/sync
GET  /api/mobile-iap/status/:courseId
GET  /student/courses/:courseId?platform=ANDROID|IOS
```

Course detail phai tra duoc cau truc tuong duong:

```json
{
  "purchase": {
    "owned": false,
    "state": "AVAILABLE",
    "mobileIap": {
      "enabled": true,
      "productId": "edtech.course.28.lifetime",
      "entitlementId": "course_28_access"
    }
  }
}
```

Neu `state` khac `AVAILABLE` hoac `productId` null, Flutter khong duoc mo purchase
flow.

## 7. Luong mua trong code

1. Course repository gui platform trong request course detail.
2. Backend tra product mapping cua platform.
3. `IapCubit.loadProduct` lay IAP config va RevenueCat App User ID tu backend.
4. `RevenueCatService.configure` cau hinh SDK bang public key dung platform.
5. SDK goi Store de lay `StoreProduct` va gia dia phuong.
6. Nguoi dung bam Pay; SDK mo purchase sheet cua Store.
7. Sau purchase, app goi `/api/mobile-iap/sync` voi reason `PURCHASE`.
8. Neu backend chua kip nhan/xac minh, app poll status sau 1, 2 va 4 giay.
9. App chi bao thanh cong khi backend tra quyen `FULL`; neu chua co thi hien
   pending.

Sau khi Store da thu tien, loi sync tam thoi khong duoc hien nhu loi thanh
toan. App giu trang thai pending de nguoi dung co the restore/sync lai trong
khi webhook va backend reconciliation hoan tat.

Restore dung cung RevenueCat App User ID do backend cap va goi sync voi reason
`RESTORE`.

## 8. Cach test Android dung

1. AAB co Billing permission phai nam trong Internal testing.
2. Release phai o trang thai available cho internal testers.
3. Gmail test phai nam trong Internal testers va License testing.
4. Tren dien thoai, dung chinh Gmail do de join opt-in link.
5. Go ban debug/`flutter run` cu neu chu ky khac.
6. Cai app tu Google Play, khong test purchase chinh bang `flutter run`.
7. Product va purchase option phai `Active`; Vietnam phai available.
8. RevenueCat product phai attach vao `course_28_access`.
9. Purchase bang test instrument va xac nhan backend tra `FULL`.
10. Test restore, reinstall, duplicate sync va refund/revoke.

Khong can dua app ra Production/Public de test; Internal testing la du.

## 9. Cach test iOS dung

1. Tao non-consumable IAP trong App Store Connect voi Product ID chinh xac.
2. Dien metadata, pricing va availability; xu ly agreement/tax/banking neu Apple
   yeu cau.
3. Import product vao RevenueCat Apple app.
4. Attach product vao entitlement `course_28_access`.
5. Dam bao backend co iOS mapping active cho course 28.
6. Test bang StoreKit configuration cho UI nhanh, sau do bat buoc test Sandbox
   hoac TestFlight cho luong that.
7. Xac nhan purchase, restore, reinstall va refund/revoke qua backend.

## 10. Bang chan doan loi

| Log/trang thai | Nguyen nhan uu tien | Xu ly |
| --- | --- | --- |
| `BILLING_UNAVAILABLE` | Device/emulator khong co Play Billing | Dung thiet bi co Play Store hoac Google Play system image |
| `PRODUCT_NOT_FOUND` | Product draft/inactive, sai ID, sai tester hoac app khong cai tu test track | Kiem tra Store product, purchase option, region, account va installer |
| `IAP_DISABLED` | Feature flag tong hoac course flag tat | Kiem tra response backend va database |
| `PRODUCT_NOT_CONFIGURED` | Khong co mapping active dung platform | Kiem tra `course_store_products` |
| Nut Pay khong co action | `StoreProduct` null hoac IAP state failure | Doc RevenueCat log va hien loi thay vi chi nhin backend log |
| Purchase thanh cong nhung course chua mo | Sync/webhook/entitlement mismatch | Kiem tra backend sync, webhook event va entitlement ID |

RevenueCat `getProducts` hoi Store truc tiep. Import product vao RevenueCat khong
the sua loi Store tra `PRODUCT_NOT_FOUND` neu Play/App Store chua san sang.

## 11. Bao mat va logging

- Public RevenueCat SDK keys duoc phep nam trong app; secret API key va webhook
  secret chi duoc nam tren backend.
- Khong log receipt, secret, service-account JSON hay subscriber attributes.
- Curl logger hien tai co the in day du `Authorization: Bearer ...` trong debug
  log. Day la known issue can redact/disable truoc khi chia se log rong rai.
- Token da lo trong log phai duoc thu hoi bang logout/login hoac cho het han.
- Khong dung email, username hoac bigint user ID lam RevenueCat App User ID.

## 12. Generated environment

Sau khi doi `env/.env.dev` hoac cac field `@Envied`, generate lai bang:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

Kiem tra `ApiPath.baseUrl = _ApiPath.baseUrl`. Neu base URL bi hard-code, generate
lai `api_path.g.dart` se khong co tac dung.

Khong commit server secret vao env mobile. Khi share log, redact Authorization.

## 13. Working tree va quyen thao tac

Agent tiep theo phai chay `git status --short` va doc diff hien tai truoc khi
sua. Khong dua vao danh sach working tree cu trong tai lieu, khong revert hoac
ghi de thay doi chua commit cua user.

Agent khong duoc build hoac chay Flutter. Build/run la viec cua user; khong suy
dien quyen build tu cac cau nhu "de tien build", "chuan bi de build" hay yeu cau
sua UI. Khi validation tinh can dung Flutter/Dart SDK, tat ca lenh phai di qua
`fvm`.

Khong duoc tu y thuc hien cac thao tac sau:

- Build APK/AAB/IPA hoac chay Flutter app.
- Chay hoac dung app/dev server/backend.
- Upload len Play Console/App Store Connect/TestFlight.
- Deploy, restart container hoac thay image.
- Chay migration hoac cap nhat database.
- Commit/push Git.

Chi user tu thuc hien build, upload va deploy.

## 14. Viec tiep theo uu tien

1. Hoan tat va xac minh Android Internal testing install.
2. Xac nhan Google Play tra product details va gia 10,000 VND.
3. Chay purchase test va xac nhan backend cap quyen `FULL`.
4. Kiem tra RevenueCat webhook, restore va refund/revoke.
5. Hoan tat App Store product va iOS sandbox/TestFlight.
6. Sua debug curl logger de khong in bearer token.
7. Bo sung unit/widget/integration tests cho cac state loi da gap.
