//
//  WorkoutManagerTests.swift
//  DroppedTests
//
//  Unit tests for WorkoutManager and WorkoutDay functionality
//

import XCTest
@testable import Dropped

final class WorkoutManagerTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Clean up any existing workouts before each test
        let existingWorkouts = WorkoutManager.shared.loadWorkouts()
        for workout in existingWorkouts {
            WorkoutManager.shared.deleteWorkout(withID: workout.id)
        }
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        let existingWorkouts = WorkoutManager.shared.loadWorkouts()
        for workout in existingWorkouts {
            WorkoutManager.shared.deleteWorkout(withID: workout.id)
        }
    }
    
    func testSaveAndLoadWorkouts() throws {
        // Create test workouts
        let workout1 = Workout(
            title: "Morning Ride",
            date: Date(),
            summary: "Easy recovery ride",
            intervals: [Interval(watts: 150, duration: 1800)]
        )
        
        let workout2 = Workout(
            title: "Interval Session",
            date: Date().addingTimeInterval(86400),
            summary: "High intensity intervals",
            intervals: [
                Interval(watts: 200, duration: 300),
                Interval(watts: 300, duration: 60)
            ]
        )
        
        // Save workouts
        WorkoutManager.shared.saveWorkout(workout1)
        WorkoutManager.shared.saveWorkout(workout2)
        
        // Load and verify
        let loadedWorkouts = WorkoutManager.shared.loadWorkouts()
        XCTAssertEqual(loadedWorkouts.count, 2, "Should have 2 workouts")
        XCTAssertTrue(loadedWorkouts.contains(where: { $0.id == workout1.id }))
        XCTAssertTrue(loadedWorkouts.contains(where: { $0.id == workout2.id }))
    }
    
    func testGetWorkoutsInDateRange() throws {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        
        // Create workouts on different dates
        let todayWorkout = Workout(
            title: "Today",
            date: today,
            summary: "Test",
            intervals: []
        )
        
        let tomorrowWorkout = Workout(
            title: "Tomorrow",
            date: tomorrow,
            summary: "Test",
            intervals: []
        )
        
        let nextWeekWorkout = Workout(
            title: "Next Week",
            date: nextWeek,
            summary: "Test",
            intervals: []
        )
        
        WorkoutManager.shared.saveWorkout(todayWorkout)
        WorkoutManager.shared.saveWorkout(tomorrowWorkout)
        WorkoutManager.shared.saveWorkout(nextWeekWorkout)
        
        // Get workouts for this week
        let weekEnd = Calendar.current.date(byAdding: .day, value: 3, to: today)!
        let thisWeekWorkouts = WorkoutManager.shared.getWorkouts(from: today, to: weekEnd)
        
        XCTAssertEqual(thisWeekWorkouts.count, 2, "Should have 2 workouts in date range")
        XCTAssertTrue(thisWeekWorkouts.contains(where: { $0.id == todayWorkout.id }))
        XCTAssertTrue(thisWeekWorkouts.contains(where: { $0.id == tomorrowWorkout.id }))
        XCTAssertFalse(thisWeekWorkouts.contains(where: { $0.id == nextWeekWorkout.id }))
    }
    
    func testWorkoutDayCreation() throws {
        // Create user data
        let userData = UserData(
            weight: 70.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 250,
            trainingHoursPerWeek: 8,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )
        
        // Save user data
        UserDataManager.shared.saveUserData(userData)
        
        // Create a workout
        let workout = Workout(
            title: "Test Workout",
            date: Date(),
            summary: "Test",
            intervals: [
                Interval(watts: 200, duration: 300),
                Interval(watts: 250, duration: 180)
            ]
        )
        
        // Create workout day
        let workoutDay = WorkoutManager.shared.createWorkoutDay(for: workout, notes: "Great session!")
        
        // Verify workout day properties
        XCTAssertEqual(workoutDay.workout.id, workout.id)
        XCTAssertEqual(workoutDay.userData.ftp, 250)
        XCTAssertEqual(workoutDay.notes, "Great session!")
        XCTAssertEqual(workoutDay.date, workout.date)
    }
    
    func testWorkoutDayRelativePower() throws {
        // Create user data with known FTP
        let userData = UserData(
            weight: 70.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 200,
            trainingHoursPerWeek: 8,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )
        
        // Create workout with 200W average (should be 1.0 relative to 200W FTP)
        let workout = Workout(
            title: "FTP Test",
            date: Date(),
            summary: "Test",
            intervals: [
                Interval(watts: 200, duration: 300)
            ]
        )
        
        let workoutDay = WorkoutDay(userData: userData, workout: workout)
        
        // Relative power should be 1.0 (200W / 200W FTP)
        XCTAssertEqual(workoutDay.relativePower, 1.0, accuracy: 0.01)
    }
    
    func testWorkoutDayRelativePowerWithDifferentIntensities() throws {
        let userData = UserData(
            weight: 70.0,
            weightUnit: WeightUnit.kilograms.rawValue,
            ftp: 200,
            trainingHoursPerWeek: 8,
            trainingGoal: TrainingGoal.getFaster.rawValue
        )
        
        // Create workout with 150W average (0.75 relative to 200W FTP)
        let workout = Workout(
            title: "Easy Ride",
            date: Date(),
            summary: "Test",
            intervals: [
                Interval(watts: 150, duration: 600)
            ]
        )
        
        let workoutDay = WorkoutDay(userData: userData, workout: workout)
        
        // Relative power should be 0.75 (150W / 200W FTP)
        XCTAssertEqual(workoutDay.relativePower, 0.75, accuracy: 0.01)
    }
    
    func testSaveAndLoadWorkoutDays() throws {
        let userData = UserData.defaultData
        UserDataManager.shared.saveUserData(userData)
        
        let workout = Workout(
            title: "Test",
            date: Date(),
            summary: "Test",
            intervals: []
        )
        
        let workoutDay = WorkoutDay(userData: userData, workout: workout, notes: "Test notes")
        
        // Save workout day
        WorkoutManager.shared.saveWorkoutDay(workoutDay)
        
        // Load and verify
        let loadedWorkoutDays = WorkoutManager.shared.loadWorkoutDays()
        XCTAssertTrue(loadedWorkoutDays.contains(where: { $0.id == workoutDay.id }))
        
        if let loaded = loadedWorkoutDays.first(where: { $0.id == workoutDay.id }) {
            XCTAssertEqual(loaded.notes, "Test notes")
            XCTAssertEqual(loaded.workout.id, workout.id)
        }
        
        // Clean up - delete the workout which should also clean up workout days
        WorkoutManager.shared.deleteWorkout(withID: workout.id)
    }
    
    func testDeleteWorkoutCleansUpWorkoutDays() throws {
        let userData = UserData.defaultData
        UserDataManager.shared.saveUserData(userData)
        
        let workout = Workout(
            title: "Test",
            date: Date(),
            summary: "Test",
            intervals: []
        )
        
        // Save workout and workout day
        WorkoutManager.shared.saveWorkout(workout)
        let workoutDay = WorkoutManager.shared.createWorkoutDay(for: workout)
        WorkoutManager.shared.saveWorkoutDay(workoutDay)
        
        // Verify both exist
        XCTAssertTrue(WorkoutManager.shared.loadWorkouts().contains(where: { $0.id == workout.id }))
        XCTAssertTrue(WorkoutManager.shared.loadWorkoutDays().contains(where: { $0.workout.id == workout.id }))
        
        // Delete workout
        WorkoutManager.shared.deleteWorkout(withID: workout.id)
        
        // Verify both are gone
        XCTAssertFalse(WorkoutManager.shared.loadWorkouts().contains(where: { $0.id == workout.id }))
        XCTAssertFalse(WorkoutManager.shared.loadWorkoutDays().contains(where: { $0.workout.id == workout.id }))
    }
}
