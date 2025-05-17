import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutDay

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if workout.title.isEmpty {
                Text("No workout title")
                    .foregroundColor(.secondary)
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityLabel("No workout title")
            } else {
                Text(workout.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
            }

            if workout.day.isEmpty {
                Text("No day specified")
                    .foregroundColor(.secondary)
                    .font(.headline)
                    .accessibilityLabel("No day specified")
            } else {
                Text("Day: \(workout.day)")
                    .font(.headline)
                    .accessibilityLabel("Day: \(workout.day)")
            }

            if workout.duration > 0 {
                Text("Duration: \(workout.duration) min")
                    .accessibilityLabel("Duration: \(workout.duration) minutes")
            } else {
                Text("Duration not specified")
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Duration not specified")
            }

            if !workout.intensity.isEmpty {
                Text("Intensity: \(workout.intensity)")
                    .accessibilityLabel("Intensity: \(workout.intensity)")
            } else {
                Text("Intensity not specified")
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Intensity not specified")
            }

            if !workout.description.isEmpty {
                Text(workout.description)
                    .padding(.top, 8)
                    .accessibilityLabel("Description: \(workout.description)")
            } else {
                Text("No description provided.")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .accessibilityLabel("No description provided.")
            }

            if let notes = (workout as? HasNotes)?.notes {
                if let notes = notes, !notes.isEmpty {
                    Text("Notes: \(notes)")
                        .italic()
                        .padding(.top, 8)
                        .accessibilityLabel("Notes: \(notes)")
                } else {
                    Text("No additional notes.")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                        .accessibilityLabel("No additional notes.")
                }
            } else {
                Text("No additional notes.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 8)
                    .accessibilityLabel("No additional notes.")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Workout Details")
        .accessibilityElement(children: .contain)
    }
}
