# SPEC Mobile IAP - RevenueCat

## 1. Thong tin tai lieu

- Du an: `Edu-Tech` (Flutter, iOS va Android).
- Muc tieu: thay luong thanh toan VNPay trong app mobile bang In-App Purchase (IAP) thong qua RevenueCat.
- Backend lien quan: xem `../Edtech-BE/spec.md`.
- Trang thai tai lieu: dac ta de trien khai, chua phai code.
- Loai san pham: mua mot lan de mo khoa vinh vien tung khoa hoc; khong phai subscription.

## 2. Muc tieu nghiep vu

1. App phat hanh tren App Store va Google Play chi mua noi dung so bang IAP cua store.
2. Moi khoa hoc tra phi la mot san pham mua mot lan rieng biet.
3. Sau khi mua thanh cong, tai khoan EduTech duoc mo khoa khoa hoc tren moi thiet bi va moi nen tang.
4. Khoa hoc da mua tren web bang VNPay van truy cap duoc trong mobile.
5. Mobile khong hien thi, mo WebView, dan link, hoac huong nguoi dung den VNPay/web checkout.
6. Luong VNPay khong bi xoa; no tiep tuc phuc vu web.
7. Quyen hoc do backend quyet dinh. Ket qua tra ve tu RevenueCat SDK chi la tin hieu de app yeu cau backend dong bo.

## 3. Hien trang can thay doi

### 3.1 Luong hien tai

`CourseDetailScreen` -> `OrderConfirmationScreen` -> `PaymentCubit.createPayment()` -> `POST /api/create-qr` -> `PaymentWebViewScreen` -> VNPay.

Backend tra `accessLevel = FULL` khi ton tai `course_registrations.payment_status = PAID`. Mobile dung `accessLevel` de mo noi dung va backend chi cap URL noi dung khi co quyen.

### 3.2 Van de hien tai

- VNPay trong mobile khong phu hop cho noi dung so tren App Store/Google Play.
- Bien `IS_PAYMENT` hien tai duoc app hieu la: neu khac `Y` thi coi nhu co full access. Cach nay khong dong bo voi backend va khong duoc tiep tuc.
- `courses.is_paid` da co trong database nhung chua duoc dung day du de quyet dinh khoa hoc mien phi/tra phi.
- Gia hien tai lay tu `courses.price` theo VND. Mobile IAP phai hien gia da dia phuong hoa tu store.

## 4. Nguyen tac kien truc bat buoc

### 4.1 Nguon su that

- Backend la nguon su that duy nhat cho quyen hoc.
- `accessLevel` tu API la gia tri duy nhat quyet dinh co duoc xem noi dung day du hay khong.
- `CustomerInfo`/entitlement tu RevenueCat khong duoc tu dong thay `accessLevel` tai client.
- App chi hien thanh cong cuoi cung sau khi backend xac nhan `accessLevel = FULL`.

### 4.2 Danh tinh RevenueCat

- Nguoi dung phai dang nhap EduTech truoc khi mua hoac restore.
- App dung `revenuecatAppUserId` do backend cap, khong dung email, username hay ID bigint hien tai.
- Khong cho phep mua o trang thai RevenueCat anonymous.
- Khi doi tai khoan, phai goi `Purchases.logIn(newRevenuecatAppUserId)` truoc khi tai san pham/mua.
- Khi logout, khong duoc de tai khoan sau nhin thay `CustomerInfo` cua tai khoan truoc. Service IAP phai chuyen ve trang thai chua xac dinh va chi `logIn` lai sau khi co user moi.

### 4.3 Loai san pham

- iOS: Non-Consumable In-App Purchase.
- Android: One-time product duoc cau hinh non-consumable trong RevenueCat.
- Mot lan mua mo khoa vinh vien mot khoa hoc, tru truong hop store refund/revoke.
- Khong consume san pham khoa hoc.
- Khong cho phep mua lai khi backend da tra `owned = true`.

### 4.4 Gia

- Mobile hien `StoreProduct.priceString` cua RevenueCat/store.
- Khong format `courses.price` thanh gia IAP.
- `courses.price` va `currency` chi la gia web/VNPay va thong tin tham khao.
- Neu RevenueCat khong tai duoc StoreProduct, nut mua bi vo hieu hoa va hien loi tai lai; khong fallback sang VNPay.

## 5. Quy tac khoa/mo khoa

| Trang thai | Quyen | Giao dien mobile |
|---|---|---|
| Chua dang nhap | `FREE` | Xem preview; yeu cau dang nhap khi mua/hoc |
| `course.isPaid = false`, da dang nhap | `FULL` | Hien `Bat dau hoc`, khong hien gia/nut mua |
| Khoa hoc tra phi, da co registration `PAID` tu bat ky kenh nao | `FULL` | Hien `Tiep tuc hoc`, khong cho mua lai |
| Khoa hoc tra phi, chua mua, IAP san sang | `FREE` | Hien gia store va nut mua IAP |
| Khoa hoc tra phi, IAP tat hoac chua map product | `FREE` | Hien tam thoi chua the mua, khong mo khoa |
| Purchase dang cho store/backend | `FREE` | Hien trang thai dang xu ly, cho phep kiem tra lai |
| Store refund/revoke va khong con quyen tu nguon khac | `FREE` | Khoa lai noi dung khong phai preview |

Quy tac uu tien: neu backend tra `accessLevel = FULL`, app luon cho hoc, bat ke khoa hoc duoc mua tu VNPay, App Store, Google Play, admin grant hay mien phi.

## 6. Cong tac bat/tat

### 6.1 Cong tac toan he thong

Dung cau hinh backend `MOBILE_IAP_ENABLED`:

- `Y`: cho phep mobile tai san pham va bat dau mua.
- `N`: an/vo hieu hoa checkout IAP.
- Cong tac nay khong duoc doi `FREE` thanh `FULL`.
- App lay gia tri moi qua API bootstrap/config, khong luu lau theo phien dang nhap.

### 6.2 Cong tac theo khoa hoc

- `isPaid = false`: khoa hoc mien phi; user dang nhap co full access.
- `isPaid = true`: can quyen mua/duoc cap.
- `mobileIapEnabled = true`: khoa hoc tra phi duoc phep ban tren mobile neu co product active cua nen tang hien tai.
- `mobileIapEnabled = false`: khoa hoc van tra phi va van bi khoa, chi khong the mua trong mobile.
- `product.active = false`: chi tat product cua nen tang do.

Khi doi trang thai khoa hoc:

- Tra phi -> mien phi: moi user da dang nhap duoc `FULL`; giao dich cu van duoc giu de audit.
- Mien phi -> tra phi: user da co free registration truoc thoi diem chuyen doi duoc giu quyen (grandfathering); user moi phai mua.

Khong su dung lai `UserService.isPayment` de mo khoa. Field `isPayment` trong login response duoc danh dau legacy va se bi loai khoi logic UI thanh toan.

## 7. RevenueCat SDK

### 7.1 Dependency va cau hinh build

- Them package Flutter chinh thuc `purchases_flutter` phien ban tuong thich voi Flutter hien tai.
- Debug/sandbox co the dung RevenueCat Test Store hoac sandbox key.
- Release bat buoc dung public SDK key rieng cho iOS va Android.
- Tuyet doi khong dua RevenueCat secret API key, webhook secret, App Store key hay Google service credential vao app.
- API key duoc nap tu env/build configuration rieng theo platform va flavor.
- Production khong duoc dung Test Store API key.

Bundle hien tai:

- iOS bundle ID: `com.nguyenduc.edtech`.
- Android application ID: `com.nguyenduc.edtech.ed_tech`.

### 7.2 IAP service

Tao mot service duy nhat, vi du `RevenueCatService`, chiu trach nhiem:

- Configure SDK dung mot lan trong lifecycle.
- Chon public key theo `Platform.isIOS`/`Platform.isAndroid`.
- Nhan `revenuecatAppUserId` tu backend va goi `Purchases.logIn`.
- Tai `StoreProduct` theo `productId` va category non-subscription.
- Purchase StoreProduct.
- Restore purchases.
- Doc `CustomerInfo` de hien trang thai tam thoi.
- Chuyen loi SDK thanh cac ma loi noi bo.
- Khong chua logic cap quyen khoa hoc.

Khi hien danh sach nhieu khoa hoc, service gom cac `productId` duy nhat va tai theo batch trong mot request `getProducts`; khong goi store tuan tu cho tung card. Cache StoreProduct theo `platform + productId` trong phien app, cho phep refresh khi app resume hoac user bam thu lai.

Flutter web khong khoi tao native IAP service. Neu repo nay duoc build cho web, web tiep tuc dung adapter VNPay rieng; code mobile khong duoc import `dart:io` theo cach lam hong web build.

### 7.3 Khoi tao va login

1. App khoi dong va khoi tao cac service co ban.
2. Sau khi co access token, goi `GET /api/mobile-iap/config`.
3. Neu user la student va platform la iOS/Android, configure RevenueCat va `logIn(revenuecatAppUserId)`.
4. Chi danh dau IAP ready khi App User ID tra ve trung voi ID backend.
5. Social login phai luu day du user/backend identity truoc khi khoi tao IAP, giong login password.
6. Neu configure/login RevenueCat loi, app van cho xem khoa hoc/preview; checkout hien loi co the thu lai.

## 8. API contract mobile su dung

Tat ca response duoi day nam trong envelope chung hien co cua `ApiClient`. Model FE phai parse dung mot cap `data` theo envelope thuc te, khong tao them cap long nhau.

### 8.1 Lay cau hinh IAP

`GET /api/mobile-iap/config?platform=IOS|ANDROID`

Yeu cau: JWT, role STUDENT.

```json
{
  "enabled": true,
  "platform": "IOS",
  "revenuecatAppUserId": "6a26b5e0-3fe2-4bad-9315-2d5162219faa"
}
```

Khong co public SDK key trong response; key nam trong build config cua app.

### 8.2 Course detail/list

App gui `platform=IOS|ANDROID` khi lay course detail. Cac field thanh toan toi thieu:

```json
{
  "courseId": "123",
  "isPaid": true,
  "accessLevel": "FREE",
  "purchase": {
    "owned": false,
    "state": "AVAILABLE",
    "mobileIap": {
      "enabled": true,
      "productId": "edtech.course.123.v1",
      "entitlementId": "course_123"
    }
  }
}
```

`purchase.state` gom:

- `FREE_COURSE`
- `OWNED`
- `AVAILABLE`
- `IAP_DISABLED`
- `PRODUCT_NOT_CONFIGURED`
- `UNAVAILABLE`

App khong tu suy dien `AVAILABLE` chi tu `isPaid`.

### 8.3 Dong bo sau purchase/restore

`POST /api/mobile-iap/sync`

```json
{
  "reason": "PURCHASE",
  "courseId": "123",
  "productId": "edtech.course.123.v1"
}
```

Voi restore:

```json
{
  "reason": "RESTORE"
}
```

Response:

```json
{
  "status": "ACTIVE",
  "courseId": "123",
  "accessLevel": "FULL",
  "paymentMethod": "APP_STORE"
}
```

`status` gom `ACTIVE`, `PENDING`, `NOT_OWNED`, `PRODUCT_MISMATCH`, `IAP_DISABLED`.

### 8.4 Kiem tra quyen

`GET /api/mobile-iap/status/:courseId`

```json
{
  "courseId": "123",
  "accessLevel": "FULL",
  "owned": true,
  "source": "APP_STORE"
}
```

## 9. Luong mua hang

1. User mo chi tiet khoa hoc.
2. App doc `accessLevel` va `purchase.state` tu backend.
3. Neu `OWNED`/`FULL`, cho hoc ngay.
4. Neu `AVAILABLE`, app tai StoreProduct dung `productId`.
5. Man xac nhan hien ten khoa hoc va `StoreProduct.priceString`.
6. User bam mua; app khoa nut de tranh double tap.
7. Goi RevenueCat purchase cho StoreProduct non-subscription.
8. Neu user cancel, tra UI ve binh thuong, khong bao purchase failed.
9. Neu SDK bao thanh cong, goi `/api/mobile-iap/sync`.
10. Neu backend tra `ACTIVE/FULL`, tai lai course detail va dieu huong den man thanh cong/khóa học.
11. Neu backend tra `PENDING`, poll `/api/mobile-iap/status/:courseId` toi da 3 lan voi backoff 1s, 2s, 4s.
12. Neu van pending, hien `Giao dich dang duoc xac minh`; khong mo khoa cuc bo. Khi user refresh/app resume thi dong bo lai.

App khong gui gia, currency, userId hay ket qua `success=true` de backend tin tuong. `courseId` va `productId` chi la goi y; backend tu xac minh voi RevenueCat va mapping database.

## 10. Restore purchases

- Them nut `Khoi phuc giao dich` trong Profile/Settings, luon co tren iOS va Android khi da dang nhap.
- Flow: `Purchases.restorePurchases()` -> `POST /api/mobile-iap/sync { reason: RESTORE }` -> refresh purchased courses va course detail.
- Thanh cong nhung khong co giao dich: hien thong bao trung tinh `Khong tim thay giao dich co the khoi phuc`.
- Neu receipt thuoc mot tai khoan EduTech khac theo restore policy, hien thong bao dang nhap dung tai khoan da mua hoac lien he ho tro; khong tu chuyen quyen.
- Restore khong duoc tao duplicate registration/payment.

## 11. UI/UX can trien khai

### 11.1 Course list/detail

- Khoa hoc mien phi: nhan `Mien phi`, khong hien gia VND nhu san pham IAP.
- Khoa hoc tra phi chua mua: gia lay tu StoreProduct.
- Khoa hoc da mua: nhan `Da so huu`/nut `Tiep tuc hoc`.
- Product dang tai: skeleton/loader o vung gia, giu kich thuoc layout on dinh.
- Product loi: `Khong the tai thong tin thanh toan` va nut thu lai.
- IAP disabled/not configured: `Khoa hoc hien chua the mua tren thiet bi nay`.

### 11.2 Order confirmation

- Tai su dung bo cuc hien tai neu phu hop, nhung action phai goi IAP thay vi `PaymentCubit.createPayment`/WebView.
- Hien gia store, ten store phu hop va noi dung duoc mo khoa.
- Khong hien logo/text VNPay tren iOS/Android.
- Khong hien gia backend neu StoreProduct chua tai xong.

### 11.3 Trang thai loi

Phan biet it nhat:

- `USER_CANCELLED`: dong sheet/dialog, khong toast loi do.
- `PAYMENT_PENDING`: giao dich dang cho xu ly.
- `PRODUCT_NOT_FOUND`: cau hinh product sai/chua active.
- `PURCHASE_NOT_ALLOWED`: store/account khong cho mua.
- `NETWORK_ERROR`: cho thu lai.
- `ALREADY_PURCHASED`: chay restore/sync roi refresh quyen.
- `VERIFICATION_PENDING`: store thanh cong nhung backend chua cap quyen.
- `ACCOUNT_CONFLICT`: purchase gan voi tai khoan EduTech khac.
- `UNKNOWN`: thong bao chung va kem correlation ID neu backend tra ve.

## 12. Thay doi module Flutter du kien

```text
lib/modules/iap/
  model/
    iap_config.dart
    course_purchase_option.dart
    iap_sync_response.dart
  repository/
    iap_repository.dart
  service/
    revenuecat_service.dart
  bloc/
    iap_cubit.dart
    iap_state.dart
  widget/
    store_price.dart
    restore_purchase_button.dart
```

- `PaymentCubit` va WebView VNPay khong con duoc goi tren iOS/Android.
- Neu Flutter web van can VNPay, tach `CheckoutCoordinator` theo platform thay vi chen dieu kien rai rac.
- `CourseDetailScreen` khong doc `UserService.isPayment` de tinh `_hasFullAccess`.
- Sau thanh cong, `CourseCubit.getCourseDetail(courseId)` phai chay lai va man truoc nhan duoc ket qua thanh cong ro rang.
- Ad manager chi tat quang cao trong thoi gian sheet thanh toan dang active; phai reset trong `finally` cho moi ket qua.

## 13. Bao mat va logging

- Khong log receipt, token store, secret key, webhook payload day du hay du lieu thanh toan nhay cam.
- Co the log: internal user ID, RevenueCat App User ID da mask, course ID, product ID, event/correlation ID va trang thai.
- Khong tin `productId`, `courseId`, gia hay user ID do client gui neu chua xac minh server-side.
- Release build tat RevenueCat debug log.

## 14. Kiem thu bat buoc

### 14.1 Unit/widget test

- Mapping course purchase state sang UI.
- Gia luon lay tu StoreProduct.
- `FULL` bo qua checkout va mo khoa.
- `IAP_DISABLED` khong mo WebView/RevenueCat purchase.
- User cancel khong hien payment failed.
- Pending khong tu cap quyen.
- Logout/login tai khoan khac khong tai su dung state IAP cu.

### 14.2 Integration/sandbox

- Mua moi tren iOS sandbox.
- Mua moi tren Google Play license tester/internal track.
- Double tap/double webhook khong tao hai quyen.
- Reinstall va restore.
- Dang nhap cung tai khoan tren thiet bi khac.
- Khoa hoc mua VNPay tren web mo duoc trong mobile.
- Refund/revoke khoa lai khoa hoc sau khi backend dong bo.
- Product ID sai/khong active.
- Webhook cham: app o `PENDING`, sau do refresh thanh `FULL`.
- Global IAP off va per-course IAP off deu khong cap quyen mien phi.
- Khoa hoc `isPaid=false` truy cap full sau dang nhap va khong goi store.

## 15. Tieu chi nghiem thu FE

- Khong con duong dan tu app mobile den VNPay/web checkout.
- Tat ca purchase mobile di qua RevenueCat SDK va native store sheet.
- App khong mo khoa truoc khi backend tra `FULL`.
- Gia mobile trung voi gia store sheet theo locale.
- Purchase/restore hoat dong cho tai khoan da dang nhap.
- Khoa hoc da mua tu bat ky kenh nao khong bi moi mua lai.
- Khoa hoc mien phi va tra phi tuan theo ma tran tai muc 5.
- iOS/Android release khong chua Test Store key hay secret key.
- Co nut restore va thong bao day du cho pending/account conflict.

## 16. Ngoai pham vi

- Subscription/thanh vien theo thang.
- Gio hang va mua nhieu khoa hoc trong mot giao dich.
- Coupon/discount do app tu tinh; discount mobile phai cau hinh tai store.
- Refund IAP tu app; refund duoc xu ly boi App Store/Google Play/RevenueCat va backend nhan webhook.
- Thay doi luong VNPay web ngoai nhung dieu chinh can thiet de dung chung quyen truy cap.

## 17. Tai lieu tham chieu

- RevenueCat Flutter SDK: https://www.revenuecat.com/docs/getting-started/installation/flutter
- RevenueCat identifying customers: https://www.revenuecat.com/docs/customers/identifying-customers
- RevenueCat non-subscription purchases: https://www.revenuecat.com/docs/platform-resources/non-subscriptions
- RevenueCat restore purchases: https://www.revenuecat.com/docs/getting-started/restoring-purchases
- Apple App Review Guideline 3.1.1: https://developer.apple.com/app-store/review/guidelines/
- Google Play Payments policy: https://support.google.com/googleplay/android-developer/answer/9858738
