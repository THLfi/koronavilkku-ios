import ExposureNotification

enum RadarStatus: Int, Codable {
    case on
    case off
    case locked
    case btOff
    case apiDisabled
    case notificationsOff
}

extension RadarStatus {
    init(from status: ENStatus) {
        switch status {
        case .active:
            self = .on
        case .bluetoothOff:
            self = .btOff
        case .disabled:
            self = .off
        default:
            self = .apiDisabled
        }
    }
}

struct DetectionStatus: Equatable {
    /// API status
    let status: RadarStatus
    
    /// Whether the detection checks are delayed and can be manually started
    let delayed: Bool
    
    /// Whether the exposure detection process is current running
    let running: Bool
    
    /// Whether exposure detection is usable or not
    ///
    /// Whenever the API is either disabled or off, or the app has been locked, the exposure
    /// detection is not in use. Bluetooth status does not affect exposure checking, though.
    func enabled() -> Bool {
        switch status {
        case .apiDisabled, .off, .locked:
            return false
            
        case .btOff, .on, .notificationsOff:
            return true
        }
    }
    
    /// Whether the user is allowed to start the exposure detection manually
    func manualCheckAllowed() -> Bool {
        return enabled() && delayed
    }
}
