import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutDay

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if workout.title.isEmpty {
                Text("No workout title")
                    .foregroundColor(.secondary)
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text(workout.title)
                    .font(.title)
                    .fontWeight(.bold)
            }

            if workout.day.isEmpty {
                Text("No day specified")
                    .foregroundColor(.secondary)
                    .font(.headline)
            } else {
                Text("Day: \(workout.day)")
                    .font(.headline)
            }

            if workout.duration > 0 {
                Text("Duration: \(workout.duration) min")
            } else {
                Text("Duration not specified")
                    .foregroundColor(.secondary)
            }

            if !workout.intensity.isEmpty {
                Text("Intensity: \(workout.intensity)")
            } else {
                Text("Intensity not specified")
                    .foregroundColor(.secondary)
            }

            if !workout.description.isEmpty {
                Text(workout.description)
                    .padding(.top, 8)
            } else {
                Text("No description provided.")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }

            if let notes = (workout as? HasNotes)?.notes {
                if let notes = notes, !notes.isEmpty {
                    Text("Notes: \(notes)")
                        .italic()
                        .padding(.top, 8)
                } else {
                    Text("No additional notes.")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                }
            } else {
                Text("No additional notes.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Workout Details")
    }
}
