# PaySplit

PaySplit helps people set up rules to divide their salary between savings wallets and beneficiaries. Users can assign a fixed amount or a percentage to each destination, review the split, and see the results in their history.

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

To sign in, use `ada@example.test` and a sample password such as `SamplePass123`. If you try the sign-up flow, use `141234` when asked for a verification code. Sign-in, verification, and transfers use local sample data in this build.

## Try the demo scenarios

Stop the running app, then start it again with the review menu:

```sh
flutter run -d emulator-5554 --dart-define=INITIAL_ROUTE=/showcase
```

- Choose **Dashboard · sample balances** to explore salary, wallets, and recent activity.
- Choose **Run Now · mixed sample outcomes** to review a split and see how successful, pending, failed, and skipped allocations are displayed.
- Choose **History · offline with saved sample**, tap **Retry**, then tap **Restore sample connection**. Saved transactions stay visible during the failed retry, and the offline notice clears after recovery.

## Approach

The screens follow the supplied PaySplit mobile designs. Sign-in, wallets and beneficiaries, split rules, and history are organized by feature. Shared buttons, form fields, and notices keep behavior consistent across screens. The offline scenario keeps saved transactions available and tells users when balances and payment statuses may be out of date.

## Tools and choices

| Tool | Why it was used |
| --- | --- |
| Flutter and Dart | Build the Android and iOS app from one codebase. |
| Riverpod | Manage form values, validation, and screen states separately from the layouts. |
| GoRouter | Handle navigation between tabs, forms, and transaction details. |
| Figma and `flutter_svg` | Use the supplied designs as a reference and render the original icons clearly at different sizes. |
| `liquid_glass_widgets` | Render the translucent bottom navigation bar. |
| `intl` | Format naira amounts and dates consistently. |
| `file_selector` | Use the device's file picker for document and photo selection. |
| Android Studio and Android Emulator | Build and run the app and verify the flows shown in the demo. |
