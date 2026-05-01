//
//  FTPTestsView.swift
//  Dropped
//

import SwiftUI

/// Lists the built-in FTP test protocols. Tapping a test saves it as a
/// scheduled `Workout` for today and navigates into the existing detail view.
struct FTPTestsView: View {
    @State private var startedWorkout: Workout?
    @State private var navigateToWorkout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick a protocol, complete the workout, then log your result. We'll compute your new FTP and update your power zones.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ForEach(FTPTestType.allCases) { test in
                    FTPTestCard(test: test) {
                        startTest(test)
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.vertical)
        }
        .navigationTitle("FTP Tests")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            Group {
                if let workout = startedWorkout {
                    NavigationLink(
                        destination: WorkoutDetailView(workout: workout),
                        isActive: $navigateToWorkout,
                        label: { EmptyView() }
                    )
                    .hidden()
                }
            }
        )
    }

    private func startTest(_ test: FTPTestType) {
        let userData = UserDataManager.shared.loadUserData()
        let workout = FTPTestWorkouts.workout(for: test, ftp: userData.ftp)
        WorkoutManager.shared.saveWorkout(workout)
        startedWorkout = workout
        navigateToWorkout = true
    }
}

private struct FTPTestCard: View {
    let test: FTPTestType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: test == .twentyMinute ? "stopwatch" : "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    Text(test.displayName)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                Text(test.summary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(test.displayName). \(test.summary)")
        .accessibilityHint("Starts the test workout")
    }
}

/// Result entry sheet after completing an FTP test. Lets the rider input the
/// key number, previews the new FTP and zones, and persists on confirm.
struct FTPTestResultEntryView: View {
    @StateObject var viewModel: FTPTestResultViewModel
    @Environment(\.dismiss) private var dismiss

    init(testType: FTPTestType, sourceWorkout: Workout? = nil) {
        _viewModel = StateObject(
            wrappedValue: FTPTestResultViewModel(
                testType: testType,
                sourceWorkout: sourceWorkout
            )
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.testType.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(viewModel.testType.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.testType.resultPrompt)
                            .font(.headline)
                        HStack {
                            TextField("Watts", text: $viewModel.inputWatts)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.inputError != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .accessibilityIdentifier("ftpResultWattsField")
                                .onChange(of: viewModel.inputWatts) { _, _ in viewModel.validate() }
                            Text("W")
                                .foregroundColor(.secondary)
                        }
                        if let error = viewModel.inputError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    beforeAfterCard

                    Button(action: confirm) {
                        Text("Update FTP")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background((viewModel.canConfirm ? Color.accentColor : Color.gray).gradient)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.canConfirm)
                    .accessibilityIdentifier("ftpResultConfirmButton")

                    Spacer(minLength: 12)
                }
                .padding()
            }
            .navigationTitle("Log Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var beforeAfterCard: some View {
        let new = viewModel.newFTP
        let delta = viewModel.delta
        return VStack(alignment: .leading, spacing: 10) {
            Text("Result Preview")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Previous")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.previousFTP) W")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("New")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(new.map { "\($0) W" } ?? "—")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(deltaColor(delta))
                }
            }

            if let d = delta, new != nil {
                Text(deltaDescription(d))
                    .font(.subheadline)
                    .foregroundColor(deltaColor(d))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func deltaColor(_ delta: Int?) -> Color {
        guard let d = delta else { return .primary }
        if d > 0 { return .green }
        if d < 0 { return .orange }
        return .primary
    }

    private func deltaDescription(_ d: Int) -> String {
        if d > 0 { return "+\(d) W vs. previous" }
        if d < 0 { return "\(d) W vs. previous" }
        return "No change"
    }

    private func confirm() {
        if viewModel.confirm() != nil {
            dismiss()
        }
    }
}
