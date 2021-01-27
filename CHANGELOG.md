# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

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
