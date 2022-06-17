# Koronavilkku iOS app

> **Note**
> 
> **As the application has been shut down, this project is no longer maintained.**

Koronavilkku is the official COVID-19 Exposure Notifications app for Finland, maintained by the Finnish Institute for Health and Welfare (THL). It uses the ExposureNotification framework, a joint effort between Apple and Google to provide the core functionality for building iOS and Android apps to notify users of possible exposure to confirmed COVID-19 cases.

https://developer.apple.com/exposure-notification/

## Setting up

Clone this Git repository, open _Koronavilkku.xcworkspace_ and run the app.

We've included a mock ExposureManager that works in the Simulator, but in order to run the app on a real device with the real Exposure Notifications API, you need to have a provisioning profile with the [correct entitlements](https://developer.apple.com/contact/request/exposure-notification-entitlement) from Apple.

### Configure the local environment

Under _./Configuration_ you can find the default configuration file _Main.xcconfig_. You can locally override the configuration values to match your environment by placing them in _LocalEnvironment.xcconfig_ (which is not checked into the VCS).

## Requirements
- Xcode 11.5 or higher
- iOS 13.5 or higher

## External dependencies
Dependencies are managed with Swift Package Manager through Xcode. Required packages should be downloaded by Xcode automatically, but if not, select File → Swift Packages → Resolve Package Versions.

### [SnapKit](https://github.com/SnapKit/SnapKit)
DSL for adding autolayout constraints to UIKit components

### [ZipFoundation](https://github.com/weichsel/ZIPFoundation)
Library for easy Zip-file handling

### [TrustKit](https://github.com/datatheorem/TrustKit)
Framework for SSL public key pinning and reporting

## Backend

See [koronavilkku-backend](https://github.com/THLfi/koronavilkku-backend) for information on application backend.

## Contributing

We are grateful for all the people who have contributed so far. Due to tight schedule of Koronavilkku release we had no time to hone the open source contribution process to the very last detail. This has caused for some contributors to do work we cannot accept due to legal details or design choices that have been made during development. For this we are sorry.

**IMPORTANT** See further details from [CONTRIBUTING.md](CONTRIBUTING.md)
