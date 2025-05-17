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
            Spacer()
        }
        .padding()
        .navigationTitle("Workout Details")
    }
}
