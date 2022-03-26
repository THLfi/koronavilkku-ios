# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- New End of Life screen that will be displayed when the EOL event is received from the backend and the application is permanently turned off 

## 2.4.3

### Changed
- Text updates for exposure guidance and infection reporting screens
- Correct UI behaviour on iOS 15: large title and scroll edge behaviour issues in the navigation bars, text alignment in attributed strings with attachments
- Update TrustKit & ZipFoundation dependencies

## 2.4.2

### Changed
- Reduced the exposure detection interval and notification retention time to 10 days
- Updated the instruction texts (and an illustration) to match the reduced voluntary quarantine period 

## 2.4.1

### Added
- In Settings, added a new link to the app accessibility statement
- New instructions after potential exposure if the user has been vaccinated or already had COVID-19

### Fixed
- Resolved a bug with the order of the onboarding steps being different from the runtime configuration

### Removed
- Cleaned up inaccessible code paths due to previously raised deployment target

## 2.3.0

### Added
- Show the number of potential exposures as an app badge
- As the stored exposure notification object had to be changed once again, added new `ExposureNotification` protocol and `DaysExposureNotification` type for handling different versions of exposure notifications

### Changed
- Switched to version 2 of the Exposure Notifications API
- iOS Deployment Target raised to 13.7
- Instead of displaying the number of potential exposures within an exposure notification, the app now displays the number of days with exposures
- The app is now responsible for showing the actual notifications 

## 2.2.1

### Added
- NotificationService for handling notification permissions and displaying local notifications
- New .notificationsOff RadarStatus when the app is functioning, but notifications are not authorized
- New onboarding step for authorizing notifications
- Main screen status view now prompts the user for notification permissions
- New instructions screen that explains how to enable the notifications in app settings

## 2.2.0

### Added
- New guide that explains what happens in case user receives an exposure notification in the future

### Changed
- Improve the instructions given to the user in case of a potential exposure
- Replaced the narrow link buttons in the home screen with a footer element
- Use new TTF font files that render more consistently with the reference design
- Break ExposuresViewWrapper into multiple views and move the related views into separate files

## 2.0.1

### Changed
- Adjust the exposure notification retention time and the detection interval duration back to 14 days

## 2.0.0

### Added
- New UI components: Checkbox, RadioButton, FadeBlock and BulletItem
- EFGSRepository for managing the EFGS interop information: initially just provides methods for storing and retrieving the participating countries
- New debug tools for displaying and removing the EFGS country data

### Changed
- Component style changes and corrections: button shadows and colors, text colors, etc. 
- Improve accessibility by adding new header traits and hints, better checkbox handling
- The infection reporting functionality has been replaced with more detailed UI flow that optionally lets the user share their travel history and diagnosis keys with the EFGS 

## 1.3.0

### Added
- Service-specific availability lookups for Omaolo municipalities 
- Let the user run the exposure detection manually if the previous check has not been completed in the last 24 hours
- New ExposureRepository publishers for the current detection status and time from the last completed detection
- Exposure status lookups in the ExposureRepository
- A loading state for RoundedButton for asynchronous tasks
- New bucket calculation for long exposures
- Display the number of the exposure notifications in the main screen
- Detailed list of exposure notifications in the potential exposure screen

### Changed
- Improve the main screen accessibility
- Changes to the app texts and localizations
- Move data binding logic to MainViewController from the main screen UIViews 

## 1.2.0

### Changed
- Small layout and rendering corrections in the main screen
- Fixed scrolling issues with navigation bar large titles
- Break potential retain cycles by using weak or unowned self in capturing closures and weak view controller delegates
- Use in-app browser for all THL links
- Adjust the exposure notification retention time to 10 days from the exposure

### Added
- New Elevation enum for adding predefined shadow styles into UIViews
- Haptic feedback when user toggles checkbox values or submits their TEK's
- New error message if a link cannot be opened in external browser due to app restrictions

## 1.1.0

### Changed
- Localisation updates
- Determine API disabled status from both exposureNotificationStatus and authorizationStatus
- Corrected instructions on how to enable EN API on iOS 13.7+

### Added
- English translation
- Show licenses of used third party libraries inside the app, accessed from the Settings tab
- Instructions on how to change the app language in Settings tab and Onboarding

## 1.0.2

### Changed
- Clean up projects file
- Define the endpoint signatures in the backend API
- Abstract file access behind a FileStorage provider
- Use exact versions for SPM dependencies
- Schedule the EN background task to run max 6 times a day to prevent it being run excessively by the system
- Suppress any errors encountered while updating the municipality list in the background task
- Ensure background task being rescheduled even if current task is unexpectedly terminated

### Added
- REST API tests
- Improved BatchRepository test coverage
- Proper TEK generation in MockExposureManager
- Git commit hash to version information in Settings view
- Show the change log in Xcode workspace

## 1.0.1

### Added
- Prefilling authorization code from SMS in case Koronavilkku is not running in background

### Fixed
- Fixed typos in Swedish localizations

### Changed
- Dummy code generation uses
