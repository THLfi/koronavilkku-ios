import XCTest
@testable import Koronavilkku

class TemporaryExposureKeyTests: XCTestCase {
    
    static let keyCount = 14

    func testGenerateKeys() throws {
        
        let keys = [String](repeating: "", count: TemporaryExposureKeyTests.keyCount).map { _ in
            TemporaryExposureKey.randomData(ofLength: TemporaryExposureKey.dataLength)
        }
        XCTAssertEqual(keys.count, TemporaryExposureKeyTests.keyCount, "Correct amount of keys")
        
        // In theory this could fail if random generator produces the same data block
        // twice but it's highly unlikely.
        let uniqueKeys = Array(Set(keys))
        XCTAssertEqual(uniqueKeys.count, keys.count, "All keys are unique")
        
        let lengths = Array(Set(uniqueKeys.map { $0.count }))
        XCTAssertEqual(1, lengths.count, "All keys are same length")
    }
}

