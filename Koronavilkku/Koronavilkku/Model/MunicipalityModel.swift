import Foundation

typealias Municipalities = [Municipality]

struct MunicipalityName : Codable {
    let fi: String
    let sv: String

    var localeString: String {
        if NSLocale.preferredLanguages.first?.starts(with: "sv") == true {
            return sv
        }
        
        return fi
    }
}

struct LocalizedContact {
    let title: String
    let phoneNumber: String
    let info: String
}

// MARK: - MunicipalityElement
struct Municipality: Codable {
    let code: String
    let name: MunicipalityName
    let omaolo: Omaolo
    let contact: Contacts
    
    var localizedContacts: [LocalizedContact] {
        contact.compactMap { $0.localizedContact }
    }
    
    func getContacts(in language: Localized.Language) -> [LocalizedContact] {
        return contact.compactMap { contact in
            guard
                let title = contact.title[keyPath: language],
                let info = contact.info[keyPath: language]
            else {
                return nil
            }
            
            return LocalizedContact(title: title, phoneNumber: contact.phoneNumber, info: info)
        }
    }

    func getContactLanguage() -> Localized.Language {
        let langs = getSupportedLanguages()
        
        if langs.contains(Localized.preferredLanguage) {
            return Localized.preferredLanguage
        } else {
            return langs.first ?? Localized.defaultLanguage
        }
    }

    private func getSupportedLanguages() -> [Localized.Language] {
        return contact.reduce([]) { (res, contact) in
            var new: [Localized.Language] = res
            
            for kp in [\Localized.fi, \Localized.sv, \Localized.en] {
                if contact.title[keyPath: kp] != nil && !new.contains(kp) {
                    new.append(kp)
                }
            }

            return new
        }
    }
}

typealias Contacts = [Contact]

// MARK: - Contact
struct Contact: Codable {
    let title: Localized
    let phoneNumber: String
    let info: Localized
    
    var localizedContact: LocalizedContact? {
        let lang = title.userLanguage
        
        if let title = title[keyPath: lang], let info = info[keyPath: lang] {
            return LocalizedContact(title: title, phoneNumber: phoneNumber, info: info)
        }
        
        return nil
    }
}

// MARK: - Omaolo
struct Omaolo: Codable {
    let available: Bool
    let serviceLanguages: ServiceLanguages?

    /// Identiers as used in the Omaolo links.
    func supportedServiceLanguageIdentifiers() -> [String] {
        var ids = [String]()
        if serviceLanguages?.fi ?? false { ids.append(OmaoloLanguageId.finnish) }
        if serviceLanguages?.sv ?? false { ids.append(OmaoloLanguageId.swedish) }
        if serviceLanguages?.en ?? false { ids.append(OmaoloLanguageId.english) }
        return ids
    }
    
    static let defaultLanguageId = OmaoloLanguageId.finnish
}

struct OmaoloLanguageId {
    static let finnish = "fi"
    static let swedish = "sv"
    static let english = "en"
}

// MARK: - ServiceLanguages
struct ServiceLanguages: Codable {
    let fi, sv: Bool
    let en: Bool?
}

// MARK: - Localized
struct Localized: Codable {
    typealias Language = KeyPath<Self, String?>
    
    let fi: String?
    let sv: String?
    let en: String?
    
    static var preferredLanguage: Language {
        switch NSLocale.preferredLanguages.first?.prefix(2) {
        case "sv":
            return \.sv
        case "en":
            return \.en
        default:
            return \.fi
        }
    }
    
    static let defaultLanguage: Language = \.fi
    
    var userLanguage: Language {
        return [Self.preferredLanguage, \.fi, \.sv, \.en].first { lang -> Bool in
            self[keyPath: lang] != nil
        } ?? \.fi
    }
    
    var localeString: String? {
        self[keyPath: userLanguage]
    }
}

enum OmaoloTarget {
    case makeEvaluation
    case contact
    
    func path(for language: String) -> String {
        switch self {
        case .makeEvaluation:
            return "/palvelut/oirearviot/649?lang=\(language)"
        case .contact:
            return "/yhteydenotto?lang=\(language)"
        }
    }
    
    func url(baseURL: String, in municipality: Municipality, language: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = baseURL
        components.path = "/api/login-application-context"
        components.queryItems = [
            URLQueryItem(name: "applicationName", value: "koronavilkku"),
            URLQueryItem(name: "municipalityCode", value: municipality.code),
            URLQueryItem(name: "returnUrl", value: path(for: language))
        ]
        return components.url!
    }
}
