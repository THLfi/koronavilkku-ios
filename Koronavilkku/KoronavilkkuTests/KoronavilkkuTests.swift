import XCTest
@testable import Koronavilkku

class KoronavilkkuTests: XCTestCase {
    func testOnboardingSteps() {
        let onboardingVC = OnboardingViewController()
        XCTAssertEqual(onboardingVC.steps.map { $0.id }, StepId.allCases)
    }
}
