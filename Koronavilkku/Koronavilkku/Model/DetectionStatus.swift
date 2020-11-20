struct DetectionStatus: Equatable {
    enum Status: Equatable {
        case disabled
        case idle
        case detecting
    }

    let status: Status
    
    /// Whether the detection checks are delayed and can be manually started
    let delayed: Bool
}
