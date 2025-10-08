//
//  WorkoutTypeTests.swift
//  DroppedTests
//
//  Unit tests for WorkoutType enum
//

import XCTest
@testable import Dropped

final class WorkoutTypeTests: XCTestCase {
    
    func testWorkoutTypeCount() throws {
        // Verify we have the expected number of workout types
        XCTAssertEqual(WorkoutType.allCases.count, 5, "Should have 5 workout types")
    }
    
    func testWorkoutTypeIdentifiers() throws {
        // Verify each type has a unique identifier
        let ids = WorkoutType.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All workout types should have unique IDs")
    }
    
    func testWorkoutTypeDisplayNames() throws {
        // Verify display names are properly set
        XCTAssertEqual(WorkoutType.endurance.displayName, "Endurance")
        XCTAssertEqual(WorkoutType.threshold.displayName, "Threshold")
        XCTAssertEqual(WorkoutType.vo2Max.displayName, "VO2 Max")
        XCTAssertEqual(WorkoutType.sprint.displayName, "Sprint")
        XCTAssertEqual(WorkoutType.recovery.displayName, "Recovery")
    }
    
    func testWorkoutTypeDescriptions() throws {
        // Verify each type has a description
        for workoutType in WorkoutType.allCases {
            XCTAssertFalse(workoutType.description.isEmpty, 
                          "\(workoutType.displayName) should have a description")
        }
    }
    
    func testEnduranceWorkoutTypeDescription() throws {
        let description = WorkoutType.endurance.description
        XCTAssertTrue(description.contains("aerobic") || description.contains("steady"), 
                     "Endurance description should mention aerobic or steady effort")
    }
    
    func testThresholdWorkoutTypeDescription() throws {
        let description = WorkoutType.threshold.description
        XCTAssertTrue(description.contains("FTP") || description.contains("power"), 
                     "Threshold description should mention FTP or power")
    }
    
    func testVO2MaxWorkoutTypeDescription() throws {
        let description = WorkoutType.vo2Max.description
        XCTAssertTrue(description.contains("intensity") || description.contains("capacity"), 
                     "VO2 Max description should mention intensity or capacity")
    }
    
    func testSprintWorkoutTypeDescription() throws {
        let description = WorkoutType.sprint.description
        XCTAssertTrue(description.contains("power") || description.contains("peak"), 
                     "Sprint description should mention power or peak")
    }
    
    func testRecoveryWorkoutTypeDescription() throws {
        let description = WorkoutType.recovery.description
        XCTAssertTrue(description.contains("recovery") || description.contains("Easy"), 
                     "Recovery description should mention recovery or easy")
    }
    
    func testWorkoutTypeRawValues() throws {
        // Verify raw values match expected
        XCTAssertEqual(WorkoutType.endurance.rawValue, "endurance")
        XCTAssertEqual(WorkoutType.threshold.rawValue, "threshold")
        XCTAssertEqual(WorkoutType.vo2Max.rawValue, "vo2Max")
        XCTAssertEqual(WorkoutType.sprint.rawValue, "sprint")
        XCTAssertEqual(WorkoutType.recovery.rawValue, "recovery")
    }
    
    func testWorkoutTypeInitFromRawValue() throws {
        // Test initialization from raw values
        XCTAssertEqual(WorkoutType(rawValue: "endurance"), .endurance)
        XCTAssertEqual(WorkoutType(rawValue: "threshold"), .threshold)
        XCTAssertEqual(WorkoutType(rawValue: "vo2Max"), .vo2Max)
        XCTAssertEqual(WorkoutType(rawValue: "sprint"), .sprint)
        XCTAssertEqual(WorkoutType(rawValue: "recovery"), .recovery)
        
        // Invalid raw value should return nil
        XCTAssertNil(WorkoutType(rawValue: "invalid"))
    }
    
    func testAllCasesContainsAllTypes() throws {
        // Verify allCases includes all expected types
        XCTAssertTrue(WorkoutType.allCases.contains(.endurance))
        XCTAssertTrue(WorkoutType.allCases.contains(.threshold))
        XCTAssertTrue(WorkoutType.allCases.contains(.vo2Max))
        XCTAssertTrue(WorkoutType.allCases.contains(.sprint))
        XCTAssertTrue(WorkoutType.allCases.contains(.recovery))
    }
    
    func testWorkoutTypeEquality() throws {
        // Test equality
        XCTAssertEqual(WorkoutType.endurance, WorkoutType.endurance)
        XCTAssertNotEqual(WorkoutType.endurance, WorkoutType.threshold)
        
        // Test with different instances
        let type1: WorkoutType = .vo2Max
        let type2: WorkoutType = .vo2Max
        XCTAssertEqual(type1, type2)
    }
}
