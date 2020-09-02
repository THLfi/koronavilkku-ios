
import Foundation

protocol Localizable : CaseIterable {
    var rawValue: String { get }
    var key: String { get }
}

private var bundlesByLanguage: [Language: Bundle] = [:]

private func getBundle(for language: Language) -> Bundle? {
    guard let bundlePath = Bundle(for: AppDelegate.self).path(forResource: language.rawValue, ofType: "lproj"),
        let bundle = Bundle(path: bundlePath) else {
            return nil
    }
    return bundle
}

extension Localizable {
    var localized: String {
        localized()
    }
    
    var key: String {
        let base = String(reflecting: type(of: self)).drop { $0 != "." }.dropFirst()
        return "\(base).\(self.rawValue)"
    }

    func localized(with args: CVarArg...) -> String {
        let language = LocalStore.shared.language
        var bundle: Bundle! = bundlesByLanguage[language]
        if bundle == nil {
            bundle = getBundle(for: language)
            bundlesByLanguage[language] = bundle
        }
        
        let localizedString: String
        if let bundle = bundle {
            localizedString = bundle.localizedString(forKey: key, value: "", table: nil)
        } else {
            localizedString = NSLocalizedString(key, comment: "")
        }
        
        return withVaList(args, { (args) -> String in
            return NSString(format: localizedString, locale: Locale.current, arguments: args) as String
        })
    }

    func toURL() -> URL? {
        return URL(string: localized)
    }
}

enum Language: String, Codable {
    case fi
    case sv
    
    static var all: [Language] {
        return [.fi, .sv]
    }
    
    static var `default`: Language {
        let code = Bundle.main.preferredLocalizations.first ?? ""
        return Language(rawValue: code) ?? .fi
    }
    
    var code: String {
        return rawValue
    }
    
    var locale: Locale {
        return Locale(identifier: code)
    }
    
    var displayName: String {
        return (locale as NSLocale).displayName(forKey: .identifier, value: code) ?? code
    }
}

/**
 Generic translations used globally in the app
 */
enum Translation: String, Localizable {
    var key: String {
        return self.rawValue
    }
    
    /* Headers and titles */
    case HeaderContinueByAcceptingExposureLogging
    case HeaderSelectMunicipality
    
    /* Subtitles, labels, etc. less significant elements */
    case ExposureNotificationUserExplanation
    case HowItWorksButton
    case AlertErrorLoadingMunicipalities
    case AlertMessagePleaseTryAgainLater
    case AlertDismissMunicipalityError
    
    /* Buttons */
    case ButtonBack
    case ButtonCancel
    case ButtonNext
    case ButtonStartUsing
    case ButtonTestUI

    /* Tabs */
    case TabHome
    case TabReportInfection
    case TabSettings
    
    case LinkAppInfo
    
    case OnboardingDone
    case OnboardingAcceptTerms
    case OnboardingReadTerms
    case OnbardingVoluntaryUse
    case OnboardingYourPrivacyIsProtected
    case OnboardingHowYourPrivacyIsProtected
    case OnboardingIntroTitle
    case OnboardingIntroText
    case OnboardingConceptTitle
    case OnboardingConceptText
    case OnboardingPrivacyTitle
    case OnboardingPrivacyText
    case OnboardingUsageTitle
    case OnboardingUsageText
    case OnboardingVoluntaryTitle
    case OnboardingVoluntaryText

    case HomeLogoLinkURL
    case HomeLogoLinkLabel
    
    case GuideTitle
    case GuideText
    case GuideSeedTitle
    case GuideSeedText
    case GuideExchangeTitle
    case GuideExchangeText
    case GuideCompareTitle
    case GuideCompareText
    case GuideNotificationTitle
    case GuideNotificationText
    case GuideDiagnosisTitle
    case GuideDiagnosisText
    case GuidePrivacyTitle
    case GuidePrivacyText
    case GuidePrivacyItem1
    case GuidePrivacyItem2
    case GuidePrivacyItem3
    case GuideButtonBack
    
    case EnableTitle
    case EnableText
    case EnableAttentionText
    case EnableButtonTitle
    case EnableButtonLabel
    case DisableTitle
    case DisableText
    case DisableInfo
    case DisableAttentionText
    case DisableButtonTitle
    case DisableButtonLabel
    case DisableConfirmTitle
    case DisableConfirmText
    case DisableConfirmButton
    case DisableCancelButton

    case BluetoothDisabledTitle
    case BluetoothDisabledText
    case ENBlockedTitle
    case ENBlockedText
    case ENBlockedSteps
    case OpenSettingsButton
    
    case ContactRequestItemTitle
    case ContactRequestItemInfo
}
