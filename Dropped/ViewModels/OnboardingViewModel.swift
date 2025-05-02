//
//  OnboardingViewModel.swift
//  Dropped
//
//  Created on 5/2/25.
//

import Foundation
import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var weight: String = "154.0" // Default in pounds
    @Published var ftp: String = "200"
    @Published var trainingHoursPerWeek: String = "5"
    @Published var selectedGoal: TrainingGoal = .haveFun
    @Published var selectedWeightUnit: WeightUnit = .pounds // Default to American units
    @Published var isMetric: Bool = false
    @Published var showStonesOption: Bool = false
    
    @Published var weightError: String? = nil
    @Published var ftpError: String? = nil
    @Published var hoursError: String? = nil
    
    init() {
        // If we've previously saved user data, load it with the proper unit conversions
        if UserDataManager.shared.hasCompletedOnboarding() {
            let userData = UserDataManager.shared.loadUserData()
            
            // Set the weight unit first to ensure proper conversion
            if let storedUnit = WeightUnit(rawValue: userData.weightUnit) {
                self.selectedWeightUnit = storedUnit
                // Set isMetric based on the stored unit preference
                self.isMetric = (storedUnit == .kilograms)
                // Set showStonesOption if stones was previously selected
                self.showStonesOption = (storedUnit == .stones)
            }
            
            // Convert the stored weight (in kg) to the selected unit and format it
            let displayWeight = userData.displayWeight()
            self.weight = String(format: "%.1f", displayWeight)
            
            self.ftp = String(userData.ftp)
            self.trainingHoursPerWeek = String(userData.trainingHoursPerWeek)
            
            if let goal = TrainingGoal.allCases.first(where: { $0.rawValue == userData.trainingGoal }) {
                self.selectedGoal = goal
            }
        }
    }
    
    func validateInputs() -> Bool {
        var isValid = true
        
        if Double(weight) == nil || Double(weight)! <= 0 {
            weightError = "Please enter a valid weight"
            isValid = false
        } else {
            weightError = nil
        }
        
        if Int(ftp) == nil || Int(ftp)! <= 0 {
            ftpError = "Please enter a valid FTP"
            isValid = false
        } else {
            ftpError = nil
        }
        
        if Int(trainingHoursPerWeek) == nil || Int(trainingHoursPerWeek)! <= 0 || Int(trainingHoursPerWeek)! > 40 {
            hoursError = "Please enter a valid training time (1-40 hours)"
            isValid = false
        } else {
            hoursError = nil
        }
        
        return isValid
    }
    
    func saveUserData() -> Bool {
        if validateInputs() {
            guard let weightValue = Double(weight) else { return false }
            
            // Convert the weight to kg for storage
            let weightInKg = selectedWeightUnit.convert(from: weightValue, to: .kilograms)
            
            let userData = UserData(
                weight: weightInKg,
                weightUnit: selectedWeightUnit.rawValue,
                ftp: Int(ftp)!,
                trainingHoursPerWeek: Int(trainingHoursPerWeek)!,
                trainingGoal: selectedGoal.rawValue
            )
            UserDataManager.shared.saveUserData(userData)
            return true
        }
        return false
    }
    
    // Toggle between metric and imperial units
    func toggleUnitSystem() {
        isMetric.toggle()
        
        // If switching to metric, always use kg
        if isMetric {
            convertWeight(to: .kilograms)
            selectedWeightUnit = .kilograms
            showStonesOption = false
        } else {
            // If switching to imperial, use previously selected imperial unit or default to pounds
            if selectedWeightUnit == .kilograms {
                convertWeight(to: .pounds)
                selectedWeightUnit = .pounds
            }
            // Allow showing stones option when in imperial mode
            showStonesOption = true
        }
    }
    
    // Handle weight unit selection within the same system (e.g., between pounds and stones)
    func selectWeightUnit(_ unit: WeightUnit) {
        if unit != selectedWeightUnit {
            convertWeight(to: unit)
            selectedWeightUnit = unit
            
            // Update isMetric flag if needed
            isMetric = (unit == .kilograms)
        }
    }
    
    // Helper to convert weight to the target unit
    private func convertWeight(to targetUnit: WeightUnit) {
        if let currentWeight = Double(weight) {
            let convertedWeight = selectedWeightUnit.convert(from: currentWeight, to: targetUnit)
            weight = String(format: "%.1f", convertedWeight)
        }
    }
}
