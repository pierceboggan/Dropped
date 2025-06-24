//
//  PlanSummaryView.swift
//  Dropped
//
//  Created on 5/2/25.
//

import SwiftUI
import Foundation

/// View that displays a summary of the user's training plan and current workouts
struct PlanSummaryView: View {
    @State private var userData: UserData
    @State private var workouts: [Workout] = []
    @Binding var hasCompletedOnboarding: Bool
    
    init(hasCompletedOnboarding: Binding<Bool>) {
        self._userData = State(initialValue: UserDataManager.shared.loadUserData())
        self._hasCompletedOnboarding = hasCompletedOnboarding
    }
    
    private var workoutPlan: [Workout] {
        return workouts.isEmpty ? generateWorkoutPlan() : workouts
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // User stats card
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Stats")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            StatCard(title: "Weight", value: String(format: "%.1f %@", userData.displayWeight(), userData.weightUnit))
                            StatCard(title: "FTP", value: "\(userData.ftp) W")
                            StatCard(title: "Time", value: "\(userData.trainingHoursPerWeek) h/week")
                        }
                        
                        Text("Goal: \(userData.trainingGoal)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Workout plan
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Weekly Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(workoutPlan) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutCard(workout: workout)
                            }
                        }
                    }
                    
                    Spacer(minLength: 30)
                    
                    Button(action: {
                        // Reset user data in memory
                        UserDataManager.shared.saveUserData(UserData.defaultData)
                        hasCompletedOnboarding = false
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Restart Onboarding")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.red.gradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle("Your Training Plan")
            .onAppear {
                refreshUserData()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "bicycle")
                            .font(.headline)
                        Text("Dropped")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
    
    // Refresh data when returning from settings
    func refreshUserData() {
        userData = UserDataManager.shared.loadUserData()
        workouts = WorkoutManager.shared.loadWorkouts()
        
        // If no workouts exist yet, generate the workout plan
        if workouts.isEmpty {
            let generatedWorkouts = generateWorkoutPlan()
            // Save the generated workouts
            for workout in generatedWorkouts {
                WorkoutManager.shared.saveWorkout(workout)
            }
            workouts = generatedWorkouts
        }
    }
    
    /// Generates a workout plan based on user's training hours per week and goal
    private func generateWorkoutPlan() -> [Workout] {
        var workouts: [Workout] = []
        let hoursPerWeek = userData.trainingHoursPerWeek
        let goal = userData.trainingGoal
        let today = Date()
        let calendar = Calendar.current
        
        // Helper function to create workout with intervals
        func createWorkout(title: String, dayOffset: Int, summary: String, duration: Int, intensity: String) -> Workout {
            // Create date for the workout
            let workoutDate = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            
            // Create some sample intervals based on intensity
            var intervals: [Interval] = []
            let totalSeconds = duration * 60
            
            // Create warm-up interval (5-10 minutes)
            let warmupDuration = min(10 * 60, totalSeconds / 5)
            intervals.append(Interval(watts: Int(Double(userData.ftp) * 0.6), duration: TimeInterval(warmupDuration)))
            
            // Create main intervals based on intensity
            var mainPower: Int
            var intervalCount: Int
            var intervalDuration: TimeInterval
            var restDuration: TimeInterval
            
            switch intensity {
            case "Low":
                mainPower = Int(Double(userData.ftp) * 0.65)
                intervals.append(Interval(watts: mainPower, duration: TimeInterval(totalSeconds - warmupDuration)))
            case "Medium-Low":
                mainPower = Int(Double(userData.ftp) * 0.75)
                intervals.append(Interval(watts: mainPower, duration: TimeInterval(totalSeconds - warmupDuration)))
            case "Medium":
                mainPower = Int(Double(userData.ftp) * 0.85)
                intervalCount = 2
                intervalDuration = TimeInterval((totalSeconds - warmupDuration) / 2)
                restDuration = 60
                
                for _ in 0..<intervalCount {
                    intervals.append(Interval(watts: mainPower, duration: intervalDuration - restDuration))
                    intervals.append(Interval(watts: Int(Double(userData.ftp) * 0.5), duration: restDuration))
                }
            case "Medium-High", "High":
                mainPower = Int(Double(userData.ftp) * 0.95)
                intervalCount = 3
                intervalDuration = TimeInterval((totalSeconds - warmupDuration) / (intervalCount * 2))
                restDuration = intervalDuration
                
                for _ in 0..<intervalCount {
                    intervals.append(Interval(watts: mainPower, duration: intervalDuration))
                    intervals.append(Interval(watts: Int(Double(userData.ftp) * 0.5), duration: restDuration))
                }
            case "Very High":
                mainPower = Int(Double(userData.ftp) * 1.1)
                intervalCount = 5
                intervalDuration = 180 // 3 minutes
                restDuration = 180 // 3 minutes
                
                for _ in 0..<intervalCount {
                    intervals.append(Interval(watts: mainPower, duration: intervalDuration))
                    intervals.append(Interval(watts: Int(Double(userData.ftp) * 0.4), duration: restDuration))
                }
            default:
                mainPower = userData.ftp
                intervals.append(Interval(watts: mainPower, duration: TimeInterval(totalSeconds - warmupDuration)))
            }
            
            return Workout(
                title: title,
                date: workoutDate,
                summary: summary,
                intervals: intervals,
                status: .scheduled
            )
        }
        
        // Basic logic to generate workouts based on goals and available time
        if hoursPerWeek <= 3 {
            // Minimal plan for those with little time
            workouts.append(createWorkout(
                title: "Recovery",
                dayOffset: 0, // Monday
                summary: "Light spinning to recover",
                duration: 30,
                intensity: "Low"
            ))
            workouts.append(createWorkout(
                title: "Tempo",
                dayOffset: 2, // Wednesday
                summary: "Sustained effort at moderate intensity",
                duration: 45,
                intensity: "Medium"
            ))
            workouts.append(createWorkout(
                title: "Endurance",
                dayOffset: 5, // Saturday
                summary: "Longer ride at conversational pace",
                duration: 60,
                intensity: "Medium-Low"
            ))
        } else if hoursPerWeek <= 6 {
            // Moderate plan
            workouts.append(createWorkout(
                title: "Recovery",
                dayOffset: 0, // Monday
                summary: "Easy spin with high cadence",
                duration: 45,
                intensity: "Low"
            ))
            workouts.append(createWorkout(
                title: "Intervals",
                dayOffset: 1, // Tuesday
                summary: "4x4 min at threshold with 2 min recovery",
                duration: 60,
                intensity: "High"
            ))
            workouts.append(createWorkout(
                title: "Tempo",
                dayOffset: 3, // Thursday
                summary: "Sustained effort at 85-90% FTP",
                duration: 60,
                intensity: "Medium-High"
            ))
            workouts.append(createWorkout(
                title: "Endurance",
                dayOffset: 5, // Saturday
                summary: "Longer ride with occasional efforts",
                duration: 90,
                intensity: "Medium"
            ))
        } else {
            // Advanced plan for those with more time
            workouts.append(createWorkout(
                title: "Active Recovery",
                dayOffset: 0, // Monday
                summary: "Easy spinning, no intensity",
                duration: 45,
                intensity: "Low"
            ))
            workouts.append(createWorkout(
                title: "VO2 Max",
                dayOffset: 1, // Tuesday
                summary: "5x3 min at 110-120% FTP with 3 min recovery",
                duration: 60,
                intensity: "Very High"
            ))
            workouts.append(createWorkout(
                title: "Endurance",
                dayOffset: 2, // Wednesday
                summary: "Steady state riding at 65-75% FTP",
                duration: 90,
                intensity: "Medium-Low"
            ))
            workouts.append(createWorkout(
                title: "Threshold",
                dayOffset: 3, // Thursday
                summary: "2x20 min at 95-100% FTP",
                duration: 75,
                intensity: "High"
            ))
            workouts.append(createWorkout(
                title: "Recovery",
                dayOffset: 4, // Friday
                summary: "Light spinning, technique drills",
                duration: 45,
                intensity: "Low"
            ))
            workouts.append(createWorkout(
                title: "Long Ride",
                dayOffset: 6, // Sunday
                summary: "Extended endurance with sweet spot intervals",
                duration: 120,
                intensity: "Medium"
            ))
        }
        
        // Adjust workouts based on goals
        if goal == TrainingGoal.getFaster.rawValue {
            // Modify existing workouts for getFaster goal
            for i in 0..<workouts.count {
                let avgPower = workouts[i].averagePower
                let ftpRatio = Double(avgPower) / Double(userData.ftp)
                
                if ftpRatio >= 0.75 && ftpRatio < 0.85 {  // If it's a "Medium" intensity workout
                    let title = workouts[i].title
                    let date = workouts[i].date
                    
                    // Create a new workout with more intense intervals
                    let newWorkout = createWorkout(
                        title: title,
                        dayOffset: 0,
                        summary: "More focused efforts with short sprints",
                        duration: Int(workouts[i].totalDuration / 60),
                        intensity: "Medium-High"
                    )
                    
                    // Replace with modified workout but keep the original date
                    workouts[i] = Workout(
                        id: newWorkout.id,
                        title: newWorkout.title,
                        date: date,
                        summary: newWorkout.summary,
                        intervals: newWorkout.intervals,
                        status: newWorkout.status
                    )
                }
            }
        } else if goal == TrainingGoal.loseWeight.rawValue {
            // Modify existing workouts for loseWeight goal
            for i in 0..<workouts.count {
                let currentWorkout = workouts[i]
                let title = currentWorkout.title
                let date = currentWorkout.date
                let duration = currentWorkout.totalDuration
                let avgPower = currentWorkout.averagePower
                let ftpRatio = Double(avgPower) / Double(userData.ftp)
                
                // Determine intensity based on FTP ratio
                var intensityString = "Medium"
                if ftpRatio < 0.65 {
                    intensityString = "Low"
                } else if ftpRatio < 0.75 {
                    intensityString = "Medium-Low"
                } else if ftpRatio < 0.85 {
                    intensityString = "Medium"
                } else if ftpRatio < 0.95 {
                    intensityString = "Medium-High"
                } else {
                    intensityString = "High"
                }
                
                // Create a new workout with longer duration
                let extendedDuration = Int(Double(duration) * 1.2 / 60) // 20% longer
                
                let newWorkout = createWorkout(
                    title: title,
                    dayOffset: 0,
                    summary: currentWorkout.summary + " (focus on steady effort)",
                    duration: extendedDuration,
                    intensity: intensityString
                )
                
                // Replace with modified workout but keep the original date
                workouts[i] = Workout(
                    id: newWorkout.id,
                    title: newWorkout.title,
                    date: date,
                    summary: newWorkout.summary,
                    intervals: newWorkout.intervals,
                    status: newWorkout.status
                )
            }
        }
        
        return workouts
    }
}

/// Card view for displaying user statistics
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(minWidth: 70)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

/// Card view for displaying workout information
struct WorkoutCard: View {
    let workout: Workout
    
    var intensityColor: Color {
        // Calculate intensity from intervals
        let avgPower = workout.averagePower
        let ftpPercent = UserDataManager.shared.loadUserData().ftp > 0 ?
            Double(avgPower) / Double(UserDataManager.shared.loadUserData().ftp) : 0.75
        
        switch ftpPercent {
        case ..<0.65: return .blue
        case 0.65..<0.75: return .green
        case 0.75..<0.85: return .yellow
        case 0.85..<0.95: return .orange
        case 0.95..<1.05: return .red
        default: return .purple
        }
    }
    
    // Format date to get day of week
    var dayOfWeek: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: workout.date)
    }
    
    // Get intensity as string
    var intensityText: String {
        let avgPower = workout.averagePower
        let ftpPercent = UserDataManager.shared.loadUserData().ftp > 0 ?
            Double(avgPower) / Double(UserDataManager.shared.loadUserData().ftp) : 0.75
        
        switch ftpPercent {
        case ..<0.65: return "Low"
        case 0.65..<0.75: return "Medium-Low"
        case 0.75..<0.85: return "Medium"
        case 0.85..<0.95: return "Medium-High"
        case 0.95..<1.05: return "High"
        default: return "Very High"
        }
    }
    
    // Format duration in minutes
    var durationText: String {
        let minutes = Int(workout.totalDuration / 60)
        return "\(minutes) min"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayOfWeek)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(durationText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 10) {
                Circle()
                    .fill(intensityColor)
                    .frame(width: 12, height: 12)
                
                Text(workout.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(intensityText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text(workout.summary)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dayOfWeek), \(workout.title) workout. \(durationText). Intensity: \(intensityText). \(workout.summary)")
    }
}

#Preview {
    PlanSummaryView(hasCompletedOnboarding: .constant(true))
}