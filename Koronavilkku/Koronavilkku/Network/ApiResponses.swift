
import Foundation

struct BatchIds: Codable {
    let batches: [String]
}

struct CurrentBatchId: Codable {
    let current: String
}
