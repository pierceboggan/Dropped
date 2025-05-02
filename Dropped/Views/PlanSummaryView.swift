//
//  PlanSummaryView.swift
//  Dropped
//
//  Created on 5/2/25.
//

import SwiftUI

struct WorkoutDay: Identifiable {
    let id = UUID()
    let day: String
    let title: String
    let description: String
    let duration: Int // minutes
    let intensity: String
}

struct PlanSummaryView: View {
    @State private var userData: UserData
    @Binding var hasCompletedOnboarding: Bool
    
    init(hasCompletedOnboarding: Binding<Bool>) {
        self._userData = State(initialValue: UserDataManager.shared.loadUserData())
        self._hasCompletedOnboarding = hasCompletedOnboarding
    }
    
    private var workoutPlan: [WorkoutDay] {
        generateWorkoutPlan()
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
                            StatCard(title: "Weight", value: "\(Int(userData.weight)) kg")
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
                            WorkoutCard(workout: workout)
                        }
                    }
                    
                    Spacer(minLength: 30)
                    
                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: "com.dropped.userdata")
                        hasCompletedOnboarding = false
                    }) {
                        Text("Restart Onboarding")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle("Your Training Plan")
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
            }
        }
    }
    
    private func generateWorkoutPlan() -> [WorkoutDay] {
        var workouts: [WorkoutDay] = []
        let hoursPerWeek = userData.trainingHoursPerWeek
        let goal = userData.trainingGoal
        
        // Basic logic to generate workouts based on goals and available time
        if hoursPerWeek <= 3 {
            // Minimal plan for those with little time
            workouts.append(WorkoutDay(day: "Monday", title: "Recovery", description: "Light spinning to recover", duration: 30, intensity: "Low"))
            workouts.append(WorkoutDay(day: "Wednesday", title: "Tempo", description: "Sustained effort at moderate intensity", duration: 45, intensity: "Medium"))
            workouts.append(WorkoutDay(day: "Saturday", title: "Endurance", description: "Longer ride at conversational pace", duration: 60, intensity: "Medium-Low"))
        } else if hoursPerWeek <= 6 {
            // Moderate plan
            workouts.append(WorkoutDay(day: "Monday", title: "Recovery", description: "Easy spin with high cadence", duration: 45, intensity: "Low"))
            workouts.append(WorkoutDay(day: "Tuesday", title: "Intervals", description: "4x4 min at threshold with 2 min recovery", duration: 60, intensity: "High"))
            workouts.append(WorkoutDay(day: "Thursday", title: "Tempo", description: "Sustained effort at 85-90% FTP", duration: 60, intensity: "Medium-High"))
            workouts.append(WorkoutDay(day: "Saturday", title: "Endurance", description: "Longer ride with occasional efforts", duration: 90, intensity: "Medium"))
        } else {
            // Advanced plan for those with more time
            workouts.append(WorkoutDay(day: "Monday", title: "Active Recovery", description: "Easy spinning, no intensity", duration: 45, intensity: "Low"))
            workouts.append(WorkoutDay(day: "Tuesday", title: "VO2 Max", description: "5x3 min at 110-120% FTP with 3 min recovery", duration: 60, intensity: "Very High"))
            workouts.append(WorkoutDay(day: "Wednesday", title: "Endurance", description: "Steady state riding at 65-75% FTP", duration: 90, intensity: "Medium-Low"))
            workouts.append(WorkoutDay(day: "Thursday", title: "Threshold", description: "2x20 min at 95-100% FTP", duration: 75, intensity: "High"))
            workouts.append(WorkoutDay(day: "Friday", title: "Recovery", description: "Light spinning, technique drills", duration: 45, intensity: "Low"))
            workouts.append(WorkoutDay(day: "Sunday", title: "Long Ride", description: "Extended endurance with sweet spot intervals", duration: 120, intensity: "Medium"))
        }
        
        // Adjust workouts based on goals
        if goal == TrainingGoal.getFaster.rawValue {
            // Increase intensity for speed-focused goals
            for (index, _) in workouts.enumerated() where workouts[index].intensity == "Medium" {
                let updatedWorkout = WorkoutDay(
                    day: workouts[index].day,
                    title: workouts[index].title,
                    description: "More focused efforts with short sprints",
                    duration: workouts[index].duration,
                    intensity: "Medium-High"
                )
                workouts[index] = updatedWorkout
            }
        } else if goal == TrainingGoal.loseWeight.rawValue {
            // Focus on longer, steady efforts for weight loss
            for (index, _) in workouts.enumerated() {
                let updatedWorkout = WorkoutDay(
                    day: workouts[index].day,
                    title: workouts[index].title,
                    description: workouts[index].description + " (focus on steady effort)",
                    duration: Int(Double(workouts[index].duration) * 1.2), // 20% longer
                    intensity: workouts[index].intensity
                )
                workouts[index] = updatedWorkout
            }
        }
        
        return workouts
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
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
    }
}

struct WorkoutCard: View {
    let workout: WorkoutDay
    
    var intensityColor: Color {
        switch workout.intensity {
        case "Low":
            return .blue
        case "Medium-Low":
            return .green
        case "Medium":
            return .yellow
        case "Medium-High":
            return .orange
        case "High", "Very High":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(workout.day)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(workout.duration) min")
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
                
                Text(workout.intensity)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text(workout.description)
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
    }
}

#Preview {
    PlanSummaryView(hasCompletedOnboarding: .constant(true))
}
