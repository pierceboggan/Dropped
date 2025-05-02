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
    @Published var weight: String = "70.0"
    @Published var ftp: String = "200"
    @Published var trainingHoursPerWeek: String = "5"
    @Published var selectedGoal: TrainingGoal = .haveFun
    
    @Published var weightError: String? = nil
    @Published var ftpError: String? = nil
    @Published var hoursError: String? = nil
    
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
            let userData = UserData(
                weight: Double(weight)!,
                ftp: Int(ftp)!,
                trainingHoursPerWeek: Int(trainingHoursPerWeek)!,
                trainingGoal: selectedGoal.rawValue
            )
            UserDataManager.shared.saveUserData(userData)
            return true
        }
        return false
    }
}
