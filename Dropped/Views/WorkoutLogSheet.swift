//
//  WorkoutLogSheet.swift
//  Dropped
//
//  Modal form used to mark a workout complete and capture the rider's
//  perceived exertion, optional metrics, and notes. The sheet doubles as the
//  edit + un-complete surface when an existing `WorkoutLog` is present.
//

import SwiftUI

/// Sheet form for creating or editing a `WorkoutLog`.
///
/// Presents the rider with a required RPE slider plus optional fields for
/// average power, average heart rate, duration override, and freeform notes.
/// All persistence is delegated to `WorkoutLogViewModel`.
struct WorkoutLogSheet: View {
    @StateObject private var viewModel: WorkoutLogViewModel
    @Environment(\.dismiss) private var dismiss

    /// Callback fired after a successful save or delete so the parent view
    /// can refresh its local state.
    private let onChange: () -> Void

    init(workout: Workout,
         existingLog: WorkoutLog? = nil,
         onChange: @escaping () -> Void) {
        self._viewModel = StateObject(
            wrappedValue: WorkoutLogViewModel(workout: workout, existingLog: existingLog)
        )
        self.onChange = onChange
    }

    var body: some View {
        NavigationView {
            Form {
                completionSection
                exertionSection
                metricsSection
                notesSection
                if viewModel.isEditing {
                    removeSection
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Log" : "Mark Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.saveButtonTitle) {
                        viewModel.save()
                        onChange()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var completionSection: some View {
        Section(header: Text("Completion")) {
            DatePicker(
                "Completed",
                selection: $viewModel.completedAt,
                displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityLabel("Completion date and time")
        }
    }

    private var exertionSection: some View {
        Section(header: Text("Perceived Exertion")) {
            HStack {
                Text("RPE")
                Spacer()
                Text("\(viewModel.perceivedExertion) / \(viewModel.rpeRange.upperBound)")
                    .font(.headline)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)

            Slider(
                value: Binding(
                    get: { Double(viewModel.perceivedExertion) },
                    set: { viewModel.perceivedExertion = WorkoutLog.clampRPE(Int($0.rounded())) }
                ),
                in: Double(viewModel.rpeRange.lowerBound)...Double(viewModel.rpeRange.upperBound),
                step: 1
            )
            .accessibilityLabel("Rate of perceived exertion")
            .accessibilityValue("\(viewModel.perceivedExertion) out of \(viewModel.rpeRange.upperBound)")
        }
    }

    private var metricsSection: some View {
        Section(header: Text("Optional Metrics")) {
            Toggle("Log average power", isOn: $viewModel.includeAveragePower)
            if viewModel.includeAveragePower {
                metricField(
                    title: "Avg power",
                    text: $viewModel.averagePowerText,
                    suffix: "W",
                    accessibility: "Average power in watts"
                )
            }

            Toggle("Log average heart rate", isOn: $viewModel.includeAverageHeartRate)
            if viewModel.includeAverageHeartRate {
                metricField(
                    title: "Avg HR",
                    text: $viewModel.averageHeartRateText,
                    suffix: "bpm",
                    accessibility: "Average heart rate in beats per minute"
                )
            }

            Toggle("Override duration", isOn: $viewModel.includeDurationOverride)
            if viewModel.includeDurationOverride {
                metricField(
                    title: "Duration",
                    text: $viewModel.durationOverrideMinutesText,
                    suffix: "min",
                    accessibility: "Actual duration in minutes"
                )
            }
        }
    }

    private var notesSection: some View {
        Section(header: Text("Notes")) {
            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 96)
                .accessibilityLabel("Session notes")
        }
    }

    private var removeSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.deleteLog()
                onChange()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove Log")
                }
            }
            .accessibilityLabel("Remove completion log")
        }
    }

    // MARK: - Helpers

    private func metricField(title: String,
                             text: Binding<String>,
                             suffix: String,
                             accessibility: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .accessibilityLabel(accessibility)
            Text(suffix)
                .foregroundColor(.secondary)
        }
    }
}
