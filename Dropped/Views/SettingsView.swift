//
//  SettingsView.swift
//  Dropped
//
//  Created on 5/2/25.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var userData: UserData
    @Published var selectedWeightUnit: WeightUnit
    @Published var isMetric: Bool
    @Published var healthSyncStatus: String?
    @Published var isRequestingHealthAuth: Bool = false

    private let healthKitService: HealthKitServicing
    private let userDataManager: UserDataManager

    init(healthKitService: HealthKitServicing = HealthKitService.shared,
         userDataManager: UserDataManager = .shared) {
        self.healthKitService = healthKitService
        self.userDataManager = userDataManager
        let loadedData = userDataManager.loadUserData()
        self.userData = loadedData

        if let storedUnit = WeightUnit(rawValue: loadedData.weightUnit) {
            self.selectedWeightUnit = storedUnit
            self.isMetric = (storedUnit == .kilograms)
        } else {
            self.selectedWeightUnit = .pounds
            self.isMetric = false
        }
    }

    var isHealthAvailable: Bool { healthKitService.isAvailable }
    
    func toggleUnitSystem() {
        isMetric.toggle()
        
        // If switching to metric, always use kg
        if isMetric {
            selectedWeightUnit = .kilograms
        } else {
            // If switching to imperial, use pounds
            selectedWeightUnit = .pounds
        }
        
        // Update userData
        updatePreferredUnit()
    }
    
    func selectWeightUnit(_ unit: WeightUnit) {
        if unit != selectedWeightUnit {
            selectedWeightUnit = unit
            
            // Update isMetric flag if needed
            isMetric = (unit == .kilograms)
            
            // Update userData
            updatePreferredUnit()
        }
    }
    
    private func updatePreferredUnit() {
        // Keep the weight value in kg, just update the display unit
        userData.weightUnit = selectedWeightUnit.rawValue
        userDataManager.saveUserData(userData)
    }

    @MainActor
    func requestHealthAuthorization() async {
        guard healthKitService.isAvailable else {
            healthSyncStatus = "Apple Health is not available on this device."
            UserDefaults.standard.set(false, forKey: WorkoutManager.healthSyncEnabledKey)
            return
        }
        isRequestingHealthAuth = true
        defer { isRequestingHealthAuth = false }
        do {
            try await healthKitService.requestAuthorization()
            let updated = await healthKitService.syncBodyMassToProfile(using: userDataManager)
            userData = userDataManager.loadUserData()
            healthSyncStatus = updated
                ? "Permissions granted. Profile weight updated from Health."
                : "Permissions granted."
        } catch {
            // Roll back the toggle so the app doesn't think sync is on after a denial/failure.
            UserDefaults.standard.set(false, forKey: WorkoutManager.healthSyncEnabledKey)
            healthSyncStatus = "Couldn't authorize Apple Health: \(error.localizedDescription)"
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage(WorkoutManager.healthSyncEnabledKey) private var healthSyncEnabled: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Measurement Units Section
                Section(header: Text("Measurement Units")) {
                    // Weight Units
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weight Unit")
                            .font(.headline)
                        
                        // Unit Selection
                        HStack(spacing: 12) {
                            // Imperial/Metric Toggle
                            HStack(spacing: 12) {
                                // Imperial button
                                Button(action: {
                                    if viewModel.isMetric {
                                        viewModel.toggleUnitSystem()
                                    }
                                }) {
                                    UnitSelectionButton(
                                        text: "Imperial",
                                        isSelected: !viewModel.isMetric,
                                        icon: "ruler"
                                    )
                                }
                                
                                // Metric button
                                Button(action: {
                                    if !viewModel.isMetric {
                                        viewModel.toggleUnitSystem()
                                    }
                                }) {
                                    UnitSelectionButton(
                                        text: "Metric",
                                        isSelected: viewModel.isMetric,
                                        icon: "scalemass"
                                    )
                                }
                            }
                        }
                        
                        // If in imperial mode, show detailed options
                        if !viewModel.isMetric {
                            Picker("Imperial Unit", selection: $viewModel.selectedWeightUnit) {
                                Text("Pounds (lb)").tag(WeightUnit.pounds)
                                Text("Stones (st)").tag(WeightUnit.stones)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.top, 8)
                            .onChange(of: viewModel.selectedWeightUnit) { _, newUnit in
                                viewModel.selectWeightUnit(newUnit)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Training Section
                Section(header: Text("Training")) {
                    NavigationLink(destination: PowerZonesView()) {
                        Label("Power Zones", systemImage: "chart.bar.fill")
                    }
                    NavigationLink(destination: FTPTestsView()) {
                        Label("Take an FTP test", systemImage: "bolt.heart")
                    }
                }

                // Apple Health Section
                Section(header: Text("Apple Health"),
                        footer: Text(viewModel.isHealthAvailable
                                     ? "When enabled, completed cycling workouts are written to Health and your weight stays in sync."
                                     : "Apple Health isn't available on this device.")) {
                    Toggle("Sync with Apple Health", isOn: $healthSyncEnabled)
                        .disabled(!viewModel.isHealthAvailable)
                        .onChange(of: healthSyncEnabled) { _, isOn in
                            guard isOn else { return }
                            Task { await viewModel.requestHealthAuthorization() }
                        }

                    Button {
                        Task { await viewModel.requestHealthAuthorization() }
                    } label: {
                        HStack {
                            Text("Re-request Permissions")
                            Spacer()
                            if viewModel.isRequestingHealthAuth {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(!viewModel.isHealthAvailable || viewModel.isRequestingHealthAuth)

                    if let status = viewModel.healthSyncStatus {
                        Text(status)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Use")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UnitSelectionButton: View {
    let text: String
    let isSelected: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .accentColor)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color(.systemGray6))
        )
        .foregroundColor(isSelected ? .white : .primary)
    }
}
