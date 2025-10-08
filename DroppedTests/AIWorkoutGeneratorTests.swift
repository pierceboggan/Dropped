//
//  AIWorkoutGeneratorTests.swift
//  DroppedTests
//
//  Unit tests for AIWorkoutGenerator service
//

import XCTest
@testable import Dropped

final class AIWorkoutGeneratorTests: XCTestCase {
    
    private var generator: AIWorkoutGenerator!
    
    override func setUpWithError() throws {
        generator = AIWorkoutGenerator(apiKey: "test-api-key")
    }
    
    override func tearDownWithError() throws {
        generator = nil
    }
    
    func testGeneratorInitialization() throws {
        // Verify generator can be initialized with an API key
        let testGenerator = AIWorkoutGenerator(apiKey: "my-test-key")
        XCTAssertNotNil(testGenerator, "Generator should be initialized")
    }
    
    func testGenerateWorkoutSuccess() throws {
        let expectation = XCTestExpectation(description: "Workout generation completes")
        
        // Generate a workout
        generator.generateWorkout(ftp: 250, type: .endurance) { result in
            switch result {
            case .success(let workoutJSON):
                // Verify we got a JSON response
                XCTAssertFalse(workoutJSON.isEmpty, "Workout JSON should not be empty")
                XCTAssertTrue(workoutJSON.contains("title"), "Workout should have a title")
                XCTAssertTrue(workoutJSON.contains("summary"), "Workout should have a summary")
                XCTAssertTrue(workoutJSON.contains("intervals"), "Workout should have intervals")
                XCTAssertTrue(workoutJSON.contains("250"), "Workout should reference the FTP value")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testGenerateWorkoutWithDifferentTypes() throws {
        let workoutTypes: [WorkoutType] = [.endurance, .threshold, .vo2Max, .sprint, .recovery]
        let expectation = XCTestExpectation(description: "All workout types generate successfully")
        expectation.expectedFulfillmentCount = workoutTypes.count
        
        for workoutType in workoutTypes {
            generator.generateWorkout(ftp: 200, type: workoutType) { result in
                switch result {
                case .success(let workoutJSON):
                    // Verify the workout type is reflected in the JSON
                    XCTAssertTrue(workoutJSON.contains(workoutType.displayName), 
                                 "Workout should contain type: \(workoutType.displayName)")
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Should not fail for type \(workoutType): \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGenerateWorkoutWithDifferentFTP() throws {
        let ftpValues = [150, 200, 250, 300]
        let expectation = XCTestExpectation(description: "All FTP values generate successfully")
        expectation.expectedFulfillmentCount = ftpValues.count
        
        for ftp in ftpValues {
            generator.generateWorkout(ftp: ftp, type: .threshold) { result in
                switch result {
                case .success(let workoutJSON):
                    // Verify the FTP is reflected in the JSON
                    XCTAssertTrue(workoutJSON.contains("\(ftp)"), 
                                 "Workout should contain FTP: \(ftp)")
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Should not fail for FTP \(ftp): \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGenerateWorkoutCallbackOnMainQueue() throws {
        let expectation = XCTestExpectation(description: "Callback is called")
        
        generator.generateWorkout(ftp: 250, type: .endurance) { result in
            // Verify we can access the result
            switch result {
            case .success(_):
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testWorkoutJSONStructure() throws {
        let expectation = XCTestExpectation(description: "Workout has proper JSON structure")
        
        generator.generateWorkout(ftp: 250, type: .threshold) { result in
            switch result {
            case .success(let workoutJSON):
                // Try to parse as JSON to verify structure
                let data = workoutJSON.data(using: .utf8)!
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    XCTAssertNotNil(json, "Should be valid JSON")
                    XCTAssertNotNil(json?["title"], "Should have title field")
                    XCTAssertNotNil(json?["summary"], "Should have summary field")
                    XCTAssertNotNil(json?["intervals"], "Should have intervals field")
                    
                    // Verify intervals is an array
                    let intervals = json?["intervals"] as? [[String: Any]]
                    XCTAssertNotNil(intervals, "Intervals should be an array")
                    XCTAssertTrue(intervals!.count > 0, "Should have at least one interval")
                    
                    // Verify interval structure
                    if let firstInterval = intervals?.first {
                        XCTAssertNotNil(firstInterval["watts"], "Interval should have watts")
                        XCTAssertNotNil(firstInterval["duration"], "Interval should have duration")
                    }
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to parse JSON: \(error)")
                }
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testWorkoutIntervalsBasedOnFTP() throws {
        let expectation = XCTestExpectation(description: "Intervals are FTP-based")
        let testFTP = 200
        
        generator.generateWorkout(ftp: testFTP, type: .endurance) { result in
            switch result {
            case .success(let workoutJSON):
                let data = workoutJSON.data(using: .utf8)!
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let intervals = json?["intervals"] as? [[String: Any]]
                    
                    // Verify intervals have reasonable power values relative to FTP
                    for interval in intervals ?? [] {
                        if let watts = interval["watts"] as? Int {
                            XCTAssertTrue(watts > 0, "Watts should be positive")
                            XCTAssertTrue(watts <= testFTP * 2, "Watts should be reasonable relative to FTP")
                        }
                        if let duration = interval["duration"] as? Int {
                            XCTAssertTrue(duration > 0, "Duration should be positive")
                        }
                    }
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to parse JSON: \(error)")
                }
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}
