# Implementation Plan - Change Password Feature

Implement the "Change Password" functionality in the Flutter application, following the logic and UI provided in the Java snippets and screenshots.

## User Review Required

> [!IMPORTANT]
> - I will add the `shared_preferences` dependency to `pubspec.yaml` to securely store user credentials and IDs locally, matching the behavior of the original Android app.
> - The `SettingsScreen` will be accessible from the gear icon in the `HomeScreen` app bar.

## Proposed Changes

### Core API & Persistence

#### [MODIFY] [pubspec.yaml](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/pubspec.yaml)
- Add `shared_preferences: ^2.2.2` to the dependencies.

#### [MODIFY] [api_service.dart](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/lib/api_service.dart)
- Update `login` method to parse the user ID from the SOAP response and return more than just a boolean (or store it).
- Add `updateUserPass` method to handle the encrypted SOAP request for changing the password.

---

### UI & Navigation

#### [NEW] [settings_screen.dart](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/lib/settings_screen.dart)
- Create a new screen with a form containing three fields:
    - Old Password
    - New Password
    - Confirm New Password
- Implement validation logic:
    - Check if the Old Password matches the stored one.
    - Check if New Password and Confirm New Password match.
    - Ensure New Password length > 3.
- Call the API and show success/error feedback.

#### [MODIFY] [home_screen.dart](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/lib/home_screen.dart)
- Update the `leading` icon button in `SliverAppBar` to navigate to `SettingsScreen`.

#### [MODIFY] [login_screen.dart](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/lib/login_screen.dart)
- Update login logic to save the user ID and password to `SharedPreferences` upon successful authentication.

## Verification Plan

### Manual Verification
- Log in to the app (credentials will be saved).
- Navigate to Settings from the Home screen.
- Test validation:
    - Entering wrong old password.
    - Entering non-matching new passwords.
    - Entering a short password.
- Test successful change:
    - Enter correct data and verify the success toast/snack bar.
    - Check if the stored password updates in local storage.
