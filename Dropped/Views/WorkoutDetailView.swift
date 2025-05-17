import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutDay

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(workout.title)
                .font(.title)
                .fontWeight(.bold)
            Text("Day: \(workout.day)")
                .font(.headline)
            Text("Duration: \(workout.duration) min")
            Text("Intensity: \(workout.intensity)")
            Text(workout.description)
                .padding(.top, 8)
            if let notes = (workout as? HasNotes)?.notes {
                if !notes.isEmpty {
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
