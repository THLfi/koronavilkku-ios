
import Foundation

struct BatchIds: Decodable {
    let batches: [String]
}

struct CurrentBatchId: Decodable {
    let current: String
}
