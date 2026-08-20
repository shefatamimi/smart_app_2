# Implement "Missing Connection" (Add Notes) Feature

Migrate the `add_notes_activity` functionality from the original Android app to Flutter. This involves fetching note types from the server, allowing the user to select one, and sending a status update for the meter.

## User Review Required

> [!NOTE]
> The `UPDATE_SIM_MNG_MASTER` SOAP call will be implemented manually in the service layer because the current `ApiClient` only supports single-parameter encrypted requests.

## Proposed Changes

### [Service Layer]

#### [MODIFY] [DirectCurrentService](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/lib/features/direct_current/services/direct_current_service.dart)
- Add `getNoteTypes()`: Fetches note types using `GetGenericsDataTable` with `DataType:49,SYSMajor:886`.
- Add `updateSimMngMaster()`: Sends the update using the `UPDATE_SIM_MNG_MASTER` SOAP action. This will use a custom XML envelope to support multiple parameters.

### [UI Layer]

#### [NEW] [AddNotesScreen](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/lib/features/meter/screens/add_notes_screen.dart)
- A new screen featuring:
  - A dropdown to select the note type (fetched from the service).
  - "Confirm" and "Cancel" buttons.
  - Loading state management.
  - Integration with `SharedPreferences` to retrieve employee info and meter number.

#### [MODIFY] [HomeScreen](file:///C:/Users/1/Desktop/smart_app-main/smart_app-main/lib/features/meter/screens/home_screen.dart)
- Connect the "فاقد الاتصال" (Missing Connection) button to navigate to the new `AddNotesScreen`.

## Verification Plan

### Manual Verification
1. Open the app and query a meter.
2. Tap the "فاقد الاتصال" (Missing Connection) button in the meter panel.
3. Verify that the "Add Notes" screen opens and loads the note types in the dropdown.
4. Select a note type and click "Confirm".
5. Verify that a success message is shown and the screen closes.
6. Verify (if possible) in the backend or logs that `UPDATE_SIM_MNG_MASTER` was called with the correct parameters.
