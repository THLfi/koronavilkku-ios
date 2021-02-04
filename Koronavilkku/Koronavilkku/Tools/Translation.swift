import UIKit

protocol Localizable : CaseIterable {
    var rawValue: String { get }
    var key: String { get }
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
        let localizedString = NSLocalizedString(key, comment: "")
        return withVaList(args, { (args) -> String in
            return NSString(format: localizedString, locale: Locale.current, arguments: args) as String
        })
    }

    func toURL() -> URL? {
        return URL(string: localized)
    }
}

protocol LocalizedView {
    associatedtype Text : Localizable
}

extension LocalizedView {
    func text(key: Text, with args: CVarArg...) -> String {
        key.localized(with: args)
    }
    
    func label(text: Text, with args: CVarArg...) -> UILabel {
        let label = UILabel()
        label.text = self.text(key: text, with: args)
        return label
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
    
    /* Subtitles, labels, etc. less significant elements */
    case ExposureNotificationUserExplanation
    case HowItWorksButton
    
    /* Buttons */
    case ButtonBack
    case ButtonCancel
    case ButtonNext
    case ButtonContinue
    case ButtonStartUsing
    case ButtonTestUI
    case ButtonLoading

    /* Tabs */
    case TabHome
    case TabReportInfection
    case TabSettings
        
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
    case ENBlockedStepsNew
    case OpenSettingsButton
    
    case ContactRequestItemTitle
    case ContactRequestItemInfo

    case ExternalLinkErrorTitle
    case ExternalLinkErrorMessage
    case ExternalLinkErrorButton
    
    case ManualCheckErrorTitle
    case ManualCheckErrorMessage
    case ManualCheckErrorButton
}
