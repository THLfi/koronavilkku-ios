import Combine
import XCTest
@testable import Koronavilkku

class MockBatchIdCache : BatchIdCache {
    var nextDiagnosisKeyFileIndex: String?
}

class BatchRepositoryTest: XCTestCase {
    private var batchRepository: BatchRepository!
    private var backend: MockBackend!
    private var cache: MockBatchIdCache!
    private var tasks = [AnyCancellable]()
    
    override func setUp() {
        backend = MockBackend()
        cache = MockBatchIdCache()
        batchRepository = BatchRepositoryImpl(backend: backend, cache: cache, fileHelper: FileHelper())
    }
    
    func testGetCurrentBatchId() {
        // no initial cache value
        XCTAssertNil(cache.nextDiagnosisKeyFileIndex)
        
        // test backend failure handling
        testPublisher(publisher: batchRepository.getCurrentBatchId(), testCompletion: { result in
            if case .failure(let error) = result {
                XCTAssertTrue(error as? MockBackend.Failure == .valueMissing)
            } else {
                XCTFail("Should never complete")
            }
        })

        // turn backend on
        backend.currentBatchId = CurrentBatchId(current: "foo")

        // cached value should not change yet
        XCTAssertNil(cache.nextDiagnosisKeyFileIndex)

        // verify the correct value is requested
        testPublisher(publisher: batchRepository.getCurrentBatchId(), testCompletion: { result in
            if case .failure = result {
                XCTFail("Should not fail")
            }
        }, testValue: { value in
            XCTAssertEqual("foo", value)
        })

        // make sure it's cached
        XCTAssertEqual(cache.nextDiagnosisKeyFileIndex, "foo")

        // backend has a new value
        backend.currentBatchId = CurrentBatchId(current: "bar")

        // should not cause a backend request
        testPublisher(publisher: batchRepository.getCurrentBatchId(), testCompletion: { result in
            if case .failure = result {
                XCTFail("Should not fail")
            }
        }, testValue: { value in
            XCTAssertEqual("foo", value)
        })

        // and definitely not modify the cache
        XCTAssertEqual(cache.nextDiagnosisKeyFileIndex, "foo")
    }
    
    private func testPublisher<T>(publisher: AnyPublisher<T, Error>,
                                  testCompletion: ((Subscribers.Completion<Error>) -> Void)? = nil,
                                  testValue: ((T) -> Void)? = nil) {
        
        let expectation = self.expectation(description: "Status code")

        publisher.sink(receiveCompletion: { result in
            testCompletion?(result)
            expectation.fulfill()
        }, receiveValue: { value in
            testValue?(value)
        }).store(in: &tasks)

        wait(for: [expectation], timeout: 5)
    }
}
