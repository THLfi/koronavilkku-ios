# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed
- Clean up projects file
- Define the endpoint signatures in the backend API
- Abstract file access behind a FileStorage provider
- Use exact versions for SPM dependencies

### Added
- REST API tests
- BatchRepository test coverage
- Implement TEK generation in MockExposureManager
- git commit hash to version information

## 1.0.1

### Added
- Prefilling authorization code from SMS in case Koronavilkku is not running in background

### Fixed
- Fixed typos in Swedish localizations

### Changed
- Dummy code generation uses
