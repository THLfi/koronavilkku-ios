# Finnish National Institute for Health and Welfare iOS Application for Covid-19 tracing

Based on the official Google/Apple Exposure Notifications API.

## Setting up

Clone the Git repository, open in Xcode and run. In order to use the Exposure Notifications API you need to install the provisioning profile with correct entitlements from Apple.

### Configure the local environment

Under _./Configuration:_ you can find the default configuration _Main.xcconfig_. You can locally override the configuration values for your environment by placing them in _LocalEnvironment.xcconfig_, without the fear of committing your local settings to everyone else.

## Requirements
- Xcode 11.5 or higher
- iOS 13.5 or higher

## External dependencies
Dependencies are managed with Swift Package Manager through Xcode. Required packages should be downloaded by Xcode automatically but if not, select File > Swift packages > Resolve package versions

### [SnapKit](https://github.com/SnapKit/SnapKit) version 5.0.1
DSL for adding autolayout constraints to UIKit components

### [ZipFoundation](https://github.com/weichsel/ZIPFoundation) version 0.9.11
Library for easy Zip-file handling

### [TrustKit](https://github.com/datatheorem/TrustKit) version 1.6.5
Framework for SSL public key pinning and reporting
