# PaySplit

PaySplit helps people set up rules to divide their salary between savings wallets and beneficiaries. Users can assign a fixed amount or a percentage to each destination, and each salary payment is split automatically and recorded in their history.

[Watch the 3:33 demo](https://drive.google.com/file/d/1J7PDpSP3JRm9YhuzgPRRAQ4s28Vs6Plm/view?usp=drivesdk). The offline retry and recovery starts at **2:48**.

## Run on Android

[Download the Android APK (60 MB)](https://drive.google.com/file/d/135zwQLThr-RW3qdjgWvr7kWTZdmqvVH1/view?usp=drivesdk) to install PaySplit on an Android device.

Install Flutter 3.44.8 and Android Studio with the Android SDK. Start an Android emulator from Android Studio's Device Manager. From the project folder, run:

```sh
flutter doctor
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Replace `emulator-5554` with the Android device ID listed by `flutter devices`.

The app connects to the provided TN Build API by default, so no extra configuration is needed. To use a different server, add `--dart-define=API_BASE_URL=https://your-server`.

## Try the app

- **Create an account** with an email address you can open. A six-digit code is sent to it. Set a password, then log in.
- **Verify your identity** from the dashboard card: phone and country, a government ID, then a selfie.
- **Set up your salary**: employer, monthly amount and pay day, a first wallet, a beneficiary, and a split rule.
- **Receive a salary** from **Profile → Simulate Salary Credit**. The API credits the salary account and runs the active rules.
- **Follow the money** on the dashboard, in **History** (search, filters, statement export, receipts) and in **Split History**.

## Approach

The screens follow the supplied PaySplit mobile designs. Sign-in, identity verification, wallets and beneficiaries, split rules, and history are organized by feature. Each feature has a data layer that calls the API and a controller that holds the screen's state, so layouts stay free of network code. Shared buttons, form fields, sheets, and notices keep behavior consistent across screens.

The access token is kept in the device's secure storage and attached to requests in one place. When a refresh fails, the last loaded data stays on screen with a notice and a retry. Requests that move money are never repeated automatically, and amounts are handled as whole kobo and only formatted for display.

## Tools and choices

| Tool | Why it was used |
| --- | --- |
| Flutter and Dart | Build the Android and iOS app from one codebase. |
| Riverpod | Manage server data, form values, validation, and screen states separately from the layouts. |
| GoRouter | Handle navigation between tabs, forms, and details, and send signed-out users to login. |
| Dio | Call the API, with one place to attach the access token and turn server errors into clear messages. |
| `flutter_secure_storage` and `shared_preferences` | Keep the access token in the Keychain or Keystore, and small settings in preferences. |
| `camera` and `image_picker` | Take the selfie for identity verification with the front camera, or choose a photo where there is no camera. |
| `file_selector` | Use the device's file picker for document and photo selection. |
| `share_plus` and `path_provider` | Share receipts and the exported statement through the system share sheet. |
| Figma and `flutter_svg` | Use the supplied designs as a reference and render the original icons clearly at different sizes. |
| `liquid_glass_widgets` | Render the translucent bottom navigation bar. |
| `intl` | Format naira amounts and dates consistently. |
| Android Studio, Android Emulator, and iOS Simulator | Build and run the app and verify the flows against the API. |
