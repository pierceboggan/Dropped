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
            Spacer()
        }
        .padding()
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    WorkoutDetailView(workout: WorkoutDay(day: "Monday", title: "Endurance Ride", description: "A steady ride at 70% FTP for aerobic development.", duration: 60, intensity: "Medium"))
}
