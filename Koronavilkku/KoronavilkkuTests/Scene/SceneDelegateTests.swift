import XCTest
@testable import Koronavilkku

class SceneDelegateTests: XCTestCase {

    let sceneDelegate = SceneDelegate()
    
    func testExtractCorrectCode() throws {
        
        // https://koronavilkku.fi/i?123456789012
        let act = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        act.webpageURL = URL(string: "https://koronavilkku.fi/i?123456789012")!
        
        let code = sceneDelegate.extractCode(userActivity: act)
        XCTAssertEqual(code, "123456789012")
    }
    
    func testExtractAlphaNumericCode() throws {
        let act = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        act.webpageURL = URL(string: "https://koronavilkku.fi/i?Foobar123")!
        
        let code = sceneDelegate.extractCode(userActivity: act)
        XCTAssertNil(code)
    }
    
    func testExtractWrongUrl() throws {
        let act = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        act.webpageURL = URL(string: "https://koronavilkku.fi/i?code=1231231")!
        
        let code = sceneDelegate.extractCode(userActivity: act)
        XCTAssertNil(code)
    }
}
