import XCTest
@testable import Koronavilkku

class LocalizationTests: XCTestCase {
    private let supportedLanguages = ["fi", "sv", "en"]
    
    func testLocalizationsDone() {
        verifyTranslations(from: Translation.self)
        verifyTranslations(from: MainViewController.Text.self)
        verifyTranslations(from: StatusHeaderView.Text.self)
        verifyTranslations(from: ExposuresElement.Text.self)
        verifyTranslations(from: ExposuresViewController.Text.self)
        verifyTranslations(from: ExposuresViewWrapper.HasExposureText.self)
        verifyTranslations(from: ExposuresViewWrapper.NoExposuresText.self)
        verifyTranslations(from: ReportInfectionViewController.Text.self)
        verifyTranslations(from: PublishTokensViewController.Text.self)
        verifyTranslations(from: ExposuresLastCheckedView.Text.self)
        verifyTranslations(from: SymptomsViewController.Text.self)
        verifyTranslations(from: SettingsViewController.Text.self)
        verifyTranslations(from: SymptomsElement.Text.self)
        verifyTranslations(from: SelectMunicipalityViewController.Text.self)
        verifyTranslations(from: LicenseListViewController.Text.self)
        verifyTranslations(from: ChangeLanguageViewController.Text.self)
    }
    
    private func verifyTranslations<T: Localizable & CaseIterable>(from namespace: T.Type) {
        for translation in namespace.allCases {
            verifyTranslations(for: translation)
        }
    }
    
    private func verifyTranslations<T: Localizable>(for localizable: T) {
        for lang in supportedLanguages {
            let bundle = getBundle(for: lang)
            let translationKey = localizable.key
            XCTAssertNotNil(bundle)
            let translation = NSLocalizedString(translationKey, tableName: nil, bundle: bundle!, value: "", comment: "")
            XCTAssertNotEqual(translationKey, translation, "Failure for \(translationKey) in language \(lang)")
        }
    }
    
    private func getBundle(for localization: String) -> Bundle? {
        guard let bundlePath = Bundle(for: LocalizationTests.self).path(forResource: localization, ofType: "lproj"), let bundle = Bundle(path: bundlePath) else {
            fatalError("This is very fatal")
        }
        return bundle
    }
}
