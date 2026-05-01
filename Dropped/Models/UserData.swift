//
//  UserData.swift
//  Dropped
//
//  Created on 5/2/25.
//

import Foundation

// MARK: - Workout Data Models

/// Represents a single workout interval, including power (watts) and duration (seconds).
struct Interval: Identifiable, Codable, Equatable {
    let id: UUID
    let watts: Int
    let duration: TimeInterval // seconds
    
    init(id: UUID = UUID(), watts: Int, duration: TimeInterval) {
        self.id = id
        self.watts = watts
        self.duration = duration
    }
}

/// Represents the completion status of a workout
enum WorkoutStatus: String, Codable, Equatable {
    case scheduled = "Scheduled"
    case completed = "Completed"
    case skipped = "Skipped"
    case inProgress = "In Progress"
}

/// Represents a workout, including overview and intervals.
struct Workout: Identifiable, Codable, Equatable {

    /// Returns an array of cumulative durations (in seconds) for each interval, useful for graphing.
    /// For example, if intervals are [5, 10, 15], returns [5, 15, 30].
    var cumulativeDurations: [TimeInterval] {
        var result: [TimeInterval] = []
        var sum: TimeInterval = 0
        for interval in intervals {
            sum += interval.duration
            result.append(sum)
        }
        return result
    }
    let id: UUID
    let title: String
    let date: Date
    let summary: String
    let intervals: [Interval]
    let status: WorkoutStatus
    /// Optional marker identifying this workout as a built-in test (e.g. an FTP test).
    /// Stored as the raw value of `FTPTestType` when applicable, nil otherwise.
    /// Decoded with `decodeIfPresent` so older persisted workouts remain readable.
    let testKind: String?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        summary: String,
        intervals: [Interval],
        status: WorkoutStatus = .scheduled,
        testKind: String? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.summary = summary
        self.intervals = intervals
        self.status = status
        self.testKind = testKind
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, date, summary, intervals, status, testKind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(Date.self, forKey: .date)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.intervals = try container.decode([Interval].self, forKey: .intervals)
        self.status = try container.decode(WorkoutStatus.self, forKey: .status)
        self.testKind = try container.decodeIfPresent(String.self, forKey: .testKind)
    }
    
    /// Calculate the total duration of the workout in seconds
    var totalDuration: TimeInterval {
        intervals.reduce(0) { $0 + $1.duration }
    }
    
    /// Calculate the average power of the workout in watts
    var averagePower: Int {
        guard !intervals.isEmpty else { return 0 }
        
        let weightedSum = intervals.reduce(0.0) { 
            $0 + (Double($1.watts) * $1.duration)
        }
        let totalDuration = intervals.reduce(0.0) { $0 + $1.duration }
        
        return totalDuration > 0 ? Int(weightedSum / totalDuration) : 0
    }
}

// MARK: - User Data Models

enum WeightUnit: String, CaseIterable, Identifiable, Codable {
    case pounds = "lb"
    case kilograms = "kg"
    case stones = "st"
    
    var id: String { self.rawValue }
    
    func convert(from value: Double, to targetUnit: WeightUnit) -> Double {
        let valueInKg: Double
        
        // Convert input to kg first
        switch self {
        case .pounds:
            valueInKg = value * 0.453592
        case .kilograms:
            valueInKg = value
        case .stones:
            valueInKg = value * 6.35029
        }
        
        // Convert from kg to target unit
        switch targetUnit {
        case .pounds:
            return valueInKg / 0.453592
        case .kilograms:
            return valueInKg
        case .stones:
            return valueInKg / 6.35029
        }
    }
}

enum TrainingGoal: String, CaseIterable, Identifiable, Codable {
    case getFaster = "Get Faster"
    case haveFun = "Have Fun"
    case loseWeight = "Lose Weight"
    case buildEndurance = "Build Endurance"
    
    var id: String { self.rawValue }
}

/// User profile data including physical and training parameters
struct UserData: Codable, Equatable {
    var weight: Double  // Always stored in kg for consistency
    var weightUnit: String // Store the preferred display unit
    var ftp: Int
    var trainingHoursPerWeek: Int
    var trainingGoal: String
    
    static let defaultData = UserData(
        weight: 70.0, 
        weightUnit: WeightUnit.pounds.rawValue,
        ftp: 200, 
        trainingHoursPerWeek: 5, 
        trainingGoal: TrainingGoal.haveFun.rawValue
    )
    
    /// Helper function to get weight in the user's preferred unit
    func displayWeight() -> Double {
        if let unit = WeightUnit(rawValue: weightUnit) {
            return WeightUnit.kilograms.convert(from: weight, to: unit)
        }
        return weight
    }

    /// Coggan power zones derived from the user's current FTP.
    var powerZones: PowerZones { PowerZones(ftp: ftp) }
}

// MARK: - Integrated Models

/// Represents a day of workouts for a user, merging user data and workout data.
///
/// This model connects a user's profile data at the time of a workout with the workout itself,
/// allowing for historical tracking of performance relative to the user's state.
struct WorkoutDay: Identifiable, Codable, Equatable {
    let id: UUID
    let userData: UserData
    let workout: Workout
    let notes: String?
    let date: Date  // This should match workout.date but is included for easier querying
    
    init(id: UUID = UUID(), userData: UserData, workout: Workout, notes: String? = nil) {
        self.id = id
        self.userData = userData
        self.workout = workout
        self.notes = notes
        self.date = workout.date
    }
    
    /// Calculate power as percentage of FTP
    var relativePower: Double {
        guard userData.ftp > 0 else { return 0 }
        return Double(workout.averagePower) / Double(userData.ftp)
    }
}

// MARK: - Data Managers

/// Manager class for persisted user data storage and retrieval.
class UserDataManager {
    static let shared = UserDataManager()
    private let userDataKey = "com.dropped.userdata"
    private let onboardingCompletedKey = "com.dropped.hasCompletedOnboarding"
    private let defaults: UserDefaults
    
    /// Internal so tests can construct an isolated instance backed by an
    /// in-memory `UserDefaults(suiteName:)`. Production code should use `.shared`.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveUserData(_ userData: UserData) {
        guard let data = try? JSONEncoder().encode(userData) else {
            assertionFailure("Failed to encode user data.")
            return
        }

        defaults.set(data, forKey: userDataKey)
        defaults.set(true, forKey: onboardingCompletedKey)
    }
    
    func loadUserData() -> UserData {
        guard let data = defaults.data(forKey: userDataKey),
              let userData = try? JSONDecoder().decode(UserData.self, from: data) else {
            return UserData.defaultData
        }

        return userData
    }
    
    func hasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: onboardingCompletedKey) && defaults.data(forKey: userDataKey) != nil
    }

    func resetUserData() {
        defaults.removeObject(forKey: userDataKey)
        defaults.removeObject(forKey: onboardingCompletedKey)
    }
}

/// Manager class for persisted workout data storage and retrieval.
class WorkoutManager {
    static let shared = WorkoutManager()
    private let workoutsKey = "com.dropped.workouts"
    private let workoutDaysKey = "com.dropped.workoutDays"
    private let defaults: UserDefaults
    
    /// Internal so tests can construct an isolated instance.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Workout Management
    
    /// Save a workout to memory
    func saveWorkout(_ workout: Workout) {
        var workouts = loadWorkouts()

        // Update existing workout or add new one
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
        } else {
            workouts.append(workout)
        }

        saveWorkouts(workouts)
    }
    
    /// Load all saved workouts
    func loadWorkouts() -> [Workout] {
        guard let data = defaults.data(forKey: workoutsKey),
              let workouts = try? JSONDecoder().decode([Workout].self, from: data) else {
            return []
        }

        return workouts
    }
    
    /// Delete a workout by ID
    func deleteWorkout(withID id: UUID) {
        var workouts = loadWorkouts()
        workouts.removeAll { $0.id == id }
        saveWorkouts(workouts)
        
        // Also clean up any workout days referencing this workout
        deleteWorkoutDays(withWorkoutID: id)
    }
    
    /// Get workouts for a specific date range
    func getWorkouts(from startDate: Date, to endDate: Date) -> [Workout] {
        return loadWorkouts().filter {
            let workoutDate = $0.date
            return workoutDate >= startDate && workoutDate <= endDate
        }
    }
    
    // MARK: - WorkoutDay Management
    
    /// Save a workout day that links user data with a workout
    func saveWorkoutDay(_ workoutDay: WorkoutDay) {
        var workoutDays = loadWorkoutDays()

        // Update existing or add new
        if let index = workoutDays.firstIndex(where: { $0.id == workoutDay.id }) {
            workoutDays[index] = workoutDay
        } else {
            workoutDays.append(workoutDay)
        }

        saveWorkoutDays(workoutDays)
    }
    
    /// Load all workout days
    func loadWorkoutDays() -> [WorkoutDay] {
        guard let data = defaults.data(forKey: workoutDaysKey),
              let workoutDays = try? JSONDecoder().decode([WorkoutDay].self, from: data) else {
            return []
        }

        return workoutDays
    }
    
    /// Delete workout days associated with a specific workout
    private func deleteWorkoutDays(withWorkoutID id: UUID) {
        var workoutDays = loadWorkoutDays()
        workoutDays.removeAll { $0.workout.id == id }
        saveWorkoutDays(workoutDays)
    }
    
    /// Get workout days for a specific date range
    func getWorkoutDays(from startDate: Date, to endDate: Date) -> [WorkoutDay] {
        return loadWorkoutDays().filter {
            let date = $0.date
            return date >= startDate && date <= endDate
        }
    }
    
    /// Create a workout day from the current user data and a workout
    func createWorkoutDay(for workout: Workout, notes: String? = nil) -> WorkoutDay {
        let userData = UserDataManager.shared.loadUserData()
        return WorkoutDay(userData: userData, workout: workout, notes: notes)
    }

    func resetWorkouts() {
        defaults.removeObject(forKey: workoutsKey)
        defaults.removeObject(forKey: workoutDaysKey)
    }

    private func saveWorkouts(_ workouts: [Workout]) {
        guard let data = try? JSONEncoder().encode(workouts) else {
            assertionFailure("Failed to encode workouts.")
            return
        }

        defaults.set(data, forKey: workoutsKey)
    }

    private func saveWorkoutDays(_ workoutDays: [WorkoutDay]) {
        guard let data = try? JSONEncoder().encode(workoutDays) else {
            assertionFailure("Failed to encode workout days.")
            return
        }

        defaults.set(data, forKey: workoutDaysKey)
    }
}
