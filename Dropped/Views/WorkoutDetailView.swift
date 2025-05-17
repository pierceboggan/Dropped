//
//  WorkoutDetailView.swift
//  Dropped
//
//  Created for workout detail feature
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutDay
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(workout.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityLabel("Workout title: \(workout.title)")

                HStack {
                    Text(workout.day)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(workout.duration) min")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Intensity:")
                        .fontWeight(.semibold)
                    Text(workout.intensity)
                        .foregroundColor(.accentColor)
                }
                .accessibilityElement(children: .combine)

                if !workout.description.isEmpty {
                    Text(workout.description)
                        .font(.body)
                        .padding(.top, 8)
                }

                // Workout preview section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.headline)
                        .padding(.bottom, 4)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            HStack {
                                Image(systemName: "bicycle")
                                    .font(.largeTitle)
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Type: \(workout.title)")
                                        .font(.subheadline)
                                    Text("Duration: \(workout.duration) min")
                                        .font(.subheadline)
                                    Text("Intensity: \(workout.intensity)")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                        )
                }
                .padding(.top, 12)

                // Intervals section
                if let intervals = workout.intervals, !intervals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intervals")
                            .font(.headline)
                            .padding(.bottom, 2)
                        ForEach(intervals) { interval in
                            HStack {
                                Text(interval.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(interval.duration) min")
                                    .foregroundColor(.secondary)
                                Text(interval.targetFTP)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer(minLength: 20)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding()
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    WorkoutDetailView(workout: WorkoutDay(day: "Monday", title: "Endurance Ride", description: "A steady ride at 70% FTP for aerobic development.", duration: 60, intensity: "Medium"))
}
