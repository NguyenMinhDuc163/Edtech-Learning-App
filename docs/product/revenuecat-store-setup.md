# RevenueCat Store Setup Runbook

This runbook records the exact App Store and Google Play setup used by the
Edu-Tech mobile app. It is written for both maintainers and future agents that
need to guide an operator through RevenueCat configuration.

The operator should be guided one screen at a time. Name the exact console,
menu, field, button, expected result, and next checkpoint. Do not say only
"configure Pub/Sub" or "grant the required permissions".

## Security Rules

Never ask the operator to paste any of these into chat, an issue, or Git:

- Apple `.p8` file contents.
- Google service-account JSON or its `private_key`.
- RevenueCat secret REST API keys.
- RevenueCat webhook authorization tokens or HMAC signing secrets.

The following are identifiers or client-side public values, not server
secrets, but should still be shared only when needed:

- RevenueCat public SDK keys (`appl_...` and `goog_...`).
- RevenueCat dashboard App IDs (`app...`).
- Apple Key ID and Issuer ID.
- Bundle ID, package name, Google Cloud project ID, and Pub/Sub topic name.

Do not "fix" a rejected key by renaming its file. Apple In-App Purchase keys
and App Store Connect API keys are different credentials even though both are
`.p8` files.

## Identifier Sources

| Item | Value |
| --- | --- |
| iOS bundle ID | `<IOS_BUNDLE_ID>` from the Xcode project and App Store Connect |
| Android package | `<ANDROID_PACKAGE_NAME>` from `android/app/build.gradle.kts` and Play Console |
| RevenueCat iOS App ID | `<REVENUECAT_IOS_APP_ID>` from the RevenueCat Apple app page |
| RevenueCat Android App ID | `<REVENUECAT_ANDROID_APP_ID>` from the RevenueCat Google app page |
| Google Cloud project ID | `<GOOGLE_CLOUD_PROJECT_ID>` from the service-account JSON metadata |
| Google Pub/Sub topic | `projects/<GOOGLE_CLOUD_PROJECT_ID>/topics/<PUBSUB_TOPIC_ID>` |

Both platform public SDK keys are already configured in the local
`env/.env.dev` and compiled through Envied into
`lib/core/constants/api_path.g.dart`. Do not copy their full values into this
document.

## Operator Guidance Protocol

When guiding setup:

1. Confirm which console and page is currently visible.
2. Give only the actions needed on that page.
3. State which similarly named option must not be selected.
4. Describe the expected success message before moving on.
5. Ask for the displayed status or a screenshot, never a private credential.
6. If an error appears, interpret that exact error before changing unrelated
   credentials.

Examples:

- Say `IAM & Admin -> IAM -> Grant access`, not "update IAM".
- Say `Pub/Sub Editor (roles/pubsub.editor)`, not "a Pub/Sub role".
- Explicitly warn against `Pub/Sub Lite Editor`.
- Say `Subscriptions, voided purchases, and all one-time products`, because
  course purchases are one-time products.

## Apple App Store Setup

### 1. Create the RevenueCat Apple app

In RevenueCat:

1. Open the project.
2. Go to `Apps & providers`.
3. Add a new App Store app.
4. Set the app name to a recognizable internal name such as
   `Edtech Production (App Store)`.
5. Set `App Bundle ID` to `<IOS_BUNDLE_ID>` and confirm it matches the
   released App Store app and Xcode project exactly.
6. Leave the generated RevenueCat custom URL scheme unchanged. The current app
   does not depend on RevenueCat paywall-preview deep links.

### 2. Create the Apple In-App Purchase key

This credential is required for StoreKit 2 transaction validation.

In App Store Connect:

1. Open `Users and Access`.
2. Open `Integrations`.
3. Under `Keys`, select `In-App Purchase`.
4. Select `Generate In-App Purchase Key`, or use `+` next to `Active`.
5. Give it a clear name such as `Edtech RevenueCat IAP`.
6. Generate and download the key. Apple permits only one download.
7. Record its Key ID and the Issuer ID shown on the page.

In RevenueCat, under `In-app purchase key configuration`:

1. Upload the In-App Purchase `.p8` file.
2. Enter the matching Key ID.
3. Enter the App Store Connect Issuer ID.
4. Save and wait for credential validation.

Reference:
[RevenueCat In-App Purchase key configuration](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration).

### 3. Create the separate App Store Connect API key

This key lets RevenueCat import products and pricing. It is not the In-App
Purchase key from the previous step.

In App Store Connect:

1. Open `Users and Access -> Integrations -> App Store Connect API`.
2. Under Team Keys, select `+`.
3. Name the key `RevenueCat App Manager`.
4. Set access to `App Manager`.
5. Generate and download `AuthKey_<KEY_ID>.p8`.
6. Record its own Key ID. The Issuer ID normally matches the account Issuer ID.

In RevenueCat, under `App Store Connect API`:

1. Upload the `AuthKey_...p8` file.
2. Enter the API key's Key ID, not the In-App Purchase Key ID.
3. Enter the Issuer ID.
4. Enter the real Vendor Number from App Store Connect
   `Payments and Financial Reports`; never use the UI example value.
5. Save and require a valid credential result.

If RevenueCat reports that the filename must be `AuthKey_XXXXXXXXXX.p8`, the
operator selected the In-App Purchase key or another private key. Return to
`App Store Connect API` and download the correct Team Key. Never rename the
wrong key.

Reference:
[RevenueCat App Store Connect API key configuration](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/app-store-connect-api-key-configuration).

### 4. Configure Apple server notifications

After both Apple credential groups validate:

1. Copy the `Apple Server Notification URL` from the RevenueCat Apple app.
2. In App Store Connect, open the Edtech app.
3. Open `General -> App Information`.
4. Find `App Store Server Notifications`.
5. Set the copied RevenueCat URL for both Production and Sandbox.
6. Select Version 2 for both environments.
7. Save.

Leave `Apple Server Notification Forwarding URL` blank unless this application
later implements a dedicated Apple-notification endpoint. The backend currently
expects RevenueCat webhooks, not forwarded raw Apple notifications.

Reference:
[RevenueCat Apple server notifications](https://www.revenuecat.com/docs/platform-resources/server-notifications/apple-server-notifications).

### 5. Capture Apple RevenueCat identifiers

From the RevenueCat Apple app page:

- Copy the public SDK key beginning with `appl_` into the mobile environment.
- Copy the RevenueCat REST API Identifier/App ID into backend
  `REVENUECAT_IOS_APP_ID`.
- Do not confuse the RevenueCat App ID with the Apple numeric app ID, Bundle
  ID, or public SDK key.

### 6. Create and attach a non-consumable course product

For every paid course sold as a lifetime purchase:

1. In App Store Connect, open the app, then
   `Monetization -> In-App Purchases`.
2. Create a `Non-Consumable` product. The Product ID must match the backend
   mapping exactly; it cannot be reused after creation.
3. Configure at least one localization, price schedule, country or region
   availability, and an App Review Screenshot.
4. If RevenueCat reports `MISSING_METADATA`, open the product in App Store
   Connect and check the App Review Screenshot first, then every required
   localization, pricing, and availability field.
5. Wait until the store status becomes `Ready to Submit`. Metadata propagation
   to Sandbox or RevenueCat can take up to one hour.
6. In RevenueCat, open `Product catalog -> Products -> Import products`, select
   the App Store app, and import the exact Product ID.
7. Open `Product catalog -> Entitlements`, select the course entitlement, and
   attach the imported App Store product.
8. Confirm the product page lists the expected entitlement under
   `Associated Entitlements`.

The current Flutter implementation loads products directly with
`Purchases.getProducts`. Therefore `No associated offerings` is expected and
does not block checkout. Do not create an Offering merely to remove that
dashboard message.

The first non-consumable product must be added to and submitted with a new app
version. `Ready to Submit` means the metadata is complete; it does not mean the
product is approved or available in production.

Current course 28 identifiers are documented in
`docs/product/mobile-iap-handoff.md`; do not duplicate public or private keys
in this runbook.

## Google Play Setup

### 1. Create the RevenueCat Google Play app

In RevenueCat:

1. Open `Apps & providers`.
2. Add a Google Play app.
3. Name it `Edtech Production (Play Store)`.
4. Set package name to `<ANDROID_PACKAGE_NAME>` and confirm it matches the
   released Play Store app and Gradle configuration exactly.
5. Leave the generated custom URL scheme unchanged.

### 2. Prepare Google Cloud APIs and service account

Use the same `<GOOGLE_CLOUD_PROJECT_ID>` as the service-account JSON. Do not
record the production project identifier in this tracked runbook.

Enable these APIs in `APIs & Services -> Library`:

- Google Play Android Developer API (`androidpublisher.googleapis.com`).
- Google Play Developer Reporting API
  (`playdeveloperreporting.googleapis.com`).
- Cloud Pub/Sub API (`pubsub.googleapis.com`).

For each API, the successful page shows `Status: Enabled` or a `Manage` button.

Create or use a dedicated service account and grant these project IAM roles:

- `Pub/Sub Editor` (`roles/pubsub.editor`).
- `Monitoring Viewer` (`roles/monitoring.viewer`).

Do not select `Pub/Sub Lite Editor`; Pub/Sub Lite is a separate product and
does not let RevenueCat list or connect the required topics. If RevenueCat must
create a topic and Editor is rejected, temporarily use `Pub/Sub Admin`, connect
the integration, and reassess whether it can be reduced afterward.

Create a JSON key for the service account, store it securely, and upload it to
the RevenueCat Google Play app. Do not commit this JSON.

### 3. Grant Google Play Console permissions

RevenueCat can parse a structurally valid JSON while still reporting
`Credentials need attention`. To grant store access:

1. Read `Client Email` from the RevenueCat credential information panel.
2. In Google Play Console, open account-level `Users and permissions`.
3. Find that service-account email or select `Invite new users`.
4. Under App permissions, add the Edtech app.
5. Grant these permissions:
   - `View app information and download bulk reports (read-only)`.
   - `View financial data, orders, and cancellation survey responses`.
   - `Manage orders and subscriptions`.
6. Save or send the invitation.
7. Re-run RevenueCat credential validation.

The required checkpoint is `Valid credentials`, with product and subscription
catalog checks passing. Google notes that new credentials can take up to 36
hours to propagate.

Reference:
[RevenueCat Google Play service credentials](https://www.revenuecat.com/docs/service-credentials/creating-play-service-credentials).

### 4. Create and connect the Pub/Sub topic

If the RevenueCat topic dropdown shows `No options`:

1. Confirm Cloud Pub/Sub API is enabled in `<GOOGLE_CLOUD_PROJECT_ID>`.
2. Confirm the JSON service account has `Pub/Sub Editor`, not the Lite role.
3. If the project has no topic, open the Google Cloud product `Pub/Sub`, then
   `Topics -> Create topic`.
4. Use a clear Topic ID such as `<PUBSUB_TOPIC_ID>`.
5. Disable `Add a default subscription`.
6. Leave schema, ingestion, retention, BigQuery export, Cloud Storage backup,
   transforms, and tags disabled or empty.
7. Keep the Google-managed encryption key.
8. Create the topic.

The resulting full name is:

```text
projects/<GOOGLE_CLOUD_PROJECT_ID>/topics/<PUBSUB_TOPIC_ID>
```

In RevenueCat:

1. Refresh the Google Play app settings.
2. Select the existing `<PUBSUB_TOPIC_ID>` topic.
3. Select `Connect to Google`.
4. Require the status `Connected to Google`.

If RevenueCat cannot create its suggested `Play-Store-Notifications` topic,
select the existing manually created topic. Do not broaden permissions merely
to create a second duplicate topic.

### 5. Allow Google Play to publish

In Google Cloud `IAM & Admin -> IAM -> Grant access`, add:

```text
google-play-developer-notifications@system.gserviceaccount.com
```

Grant exactly `Pub/Sub Publisher` (`roles/pubsub.publisher`), not the Pub/Sub
Lite role. A topic-level grant is narrower, but a project-level grant is an
acceptable operational fallback for this dedicated project.

### 6. Configure Real-Time Developer Notifications

In Google Play Console:

1. Select the Edtech app.
2. Open `Monetize with Play -> Monetization setup`.
3. Under `Real-time developer notifications`, select `Manage notifications`.
4. Enable real-time notifications.
5. Set Topic name to:

```text
projects/<GOOGLE_CLOUD_PROJECT_ID>/topics/<PUBSUB_TOPIC_ID>
```

6. Select `Subscriptions, voided purchases, and all one-time products`.
7. Save changes.
8. Select `Send test notification`.

Refresh RevenueCat. The success checkpoint is:

- `Connected to Google`.
- `Last received <timestamp>` instead of `No notifications received`.

Leave `Track new purchases from server-to-server notifications` disabled for
the current integration. The RevenueCat SDK posts purchases and logs in with
the backend-issued UUID identity; enabling server-first tracking can introduce
an anonymous-customer race unless identity behavior is deliberately redesigned.

Reference:
[RevenueCat Google real-time notifications](https://www.revenuecat.com/docs/platform-resources/server-notifications/google-server-notifications).

### 7. Capture Android RevenueCat identifiers

From the RevenueCat Google Play app page:

- Copy the public SDK key beginning with `goog_` into the mobile environment.
- Copy the RevenueCat App ID into backend `REVENUECAT_ANDROID_APP_ID`.
- Leave Offerings compatibility mode disabled for the current direct-product
  implementation.
- Leave Financial Reports Bucket blank unless financial report ingestion is
  intentionally introduced.

## Applying Mobile Public Keys

Store local values in `env/.env.dev`:

```dotenv
REVENUECAT_IOS_PUBLIC_API_KEY="appl_..."
REVENUECAT_ANDROID_PUBLIC_API_KEY="goog_..."
```

The file is ignored by Git. Envied generates obfuscated Dart constants into a
tracked generated file. Environment changes may be missed by incremental
`build_runner`; use the clean step when a run reports that all inputs were
skipped:

```bash
/home/nguyenduc/fvm/versions/3.29.2/bin/dart run build_runner clean
/home/nguyenduc/fvm/versions/3.29.2/bin/dart run build_runner build --delete-conflicting-outputs
/home/nguyenduc/fvm/versions/3.29.2/bin/flutter analyze --no-fatal-infos --no-fatal-warnings \
  lib/core/constants/api_path.dart \
  lib/core/constants/api_path.g.dart \
  lib/modules/iap
```

Never put `REVENUECAT_SECRET_API_KEY`, webhook authorization, HMAC secrets, or
store private credentials in the Flutter environment.

## Backend Environment Handoff

The store setup provides these backend-safe identifiers:

```dotenv
REVENUECAT_IOS_APP_ID=<REVENUECAT_IOS_APP_ID>
REVENUECAT_ANDROID_APP_ID=<REVENUECAT_ANDROID_APP_ID>
REVENUECAT_ALLOWED_ENVIRONMENTS=SANDBOX,PRODUCTION
REVENUECAT_API_BASE_URL=https://api.revenuecat.com/v1
```

The remaining server-only values are obtained or created during backend
RevenueCat configuration:

```dotenv
REVENUECAT_SECRET_API_KEY=
REVENUECAT_WEBHOOK_AUTH_TOKEN=
REVENUECAT_WEBHOOK_HMAC_SECRET=
```

The current backend calls RevenueCat REST API v1, so its secret key must be
compatible with v1. Webhook authorization is an operator-generated random
token; the HMAC signing secret is copied once from the RevenueCat webhook
integration after HMAC signing is enabled.

## Final Store Checklist

Apple:

- Bundle ID matches the released app.
- In-App Purchase key validates.
- Separate App Store Connect API key validates.
- Vendor Number is real, not a placeholder.
- Production and Sandbox server notification URLs use RevenueCat and Version 2.
- App Store product is imported into the correct RevenueCat Apple app.
- Product is attached to the matching course entitlement.
- `No associated offerings` is accepted for the direct-product implementation.
- Backend has an active `IOS` + `APP_STORE` product mapping.
- The first non-consumable is included with a new app version submission.
- Flutter uses the platform Apple public SDK key, not a Test Store key.

Google:

- Package name matches the released app.
- RevenueCat reports valid service credentials.
- Service account has the required Play Console permissions.
- Cloud Pub/Sub API is enabled.
- Service account uses regular Pub/Sub roles, not Pub/Sub Lite.
- RevenueCat reports `Connected to Google`.
- Google Play test notification produces a RevenueCat `Last received` time.
- Flutter uses the platform Google public SDK key, not a Test Store key.
