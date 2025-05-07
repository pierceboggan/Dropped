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
    
    init() {
        self.userData = UserDataManager.shared.loadUserData()
        if let storedUnit = WeightUnit(rawValue: userData.weightUnit) {
            self.selectedWeightUnit = storedUnit
            self.isMetric = (storedUnit == .kilograms)
        } else {
            self.selectedWeightUnit = .pounds
            self.isMetric = false
        }
    }
    
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
        UserDataManager.shared.saveUserData(userData)
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
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
                            .onChange(of: viewModel.selectedWeightUnit) { newUnit in
                                viewModel.selectWeightUnit(newUnit)
                            }
                        }
                    }
                    .padding(.vertical, 8)
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

#Preview {
    SettingsView()
}
