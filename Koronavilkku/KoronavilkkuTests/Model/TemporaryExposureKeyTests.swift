import XCTest
@testable import Koronavilkku

import XCTest

class TemporaryExposureKeyTests: XCTestCase {

    func testGenerateKeys() throws {
        
        let keys = [String](repeating: "", count: 14).map { _ in
            TemporaryExposureKey.randomData(ofLength: TemporaryExposureKey.dataLength)
        }
        XCTAssertEqual(14, keys.count)
        print(keys)
    }
}
