//
//  UserData.swift
//  Dropped
//
//  Created on 5/2/25.
//

import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case pounds = "lb"
    case kilograms = "kg"
    case stones = "st"
    
    var id: String { self.rawValue }
    
    func convert(from value: Double, to targetUnit: WeightUnit) -> Double {
        let valueInKg: Double
        
        // Convert input to kg first
        switch self {
        case .pounds:
            valueInKg = value * 0.453592
        case .kilograms:
            valueInKg = value
        case .stones:
            valueInKg = value * 6.35029
        }
        
        // Convert from kg to target unit
        switch targetUnit {
        case .pounds:
            return valueInKg / 0.453592
        case .kilograms:
            return valueInKg
        case .stones:
            return valueInKg / 6.35029
        }
    }
}

enum TrainingGoal: String, CaseIterable, Identifiable {
    case getFaster = "Get Faster"
    case haveFun = "Have Fun"
    case loseWeight = "Lose Weight"
    case buildEndurance = "Build Endurance"
    
    var id: String { self.rawValue }
}

struct UserData: Codable {
    var weight: Double  // Always stored in kg for consistency
    var weightUnit: String // Store the preferred display unit
    var ftp: Int
    var trainingHoursPerWeek: Int
    var trainingGoal: String
    
    static let defaultData = UserData(
        weight: 70.0, 
        weightUnit: WeightUnit.pounds.rawValue,
        ftp: 200, 
        trainingHoursPerWeek: 5, 
        trainingGoal: TrainingGoal.haveFun.rawValue
    )
    
    // Helper function to get weight in the user's preferred unit
    func displayWeight() -> Double {
        if let unit = WeightUnit(rawValue: weightUnit) {
            return WeightUnit.kilograms.convert(from: weight, to: unit)
        }
        return weight
    }
}

class UserDataManager {
    static let shared = UserDataManager()
    
    private let userDataKey = "com.dropped.userdata"
    
    func saveUserData(_ userData: UserData) {
        if let encoded = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(encoded, forKey: userDataKey)
        }
    }
    
    func loadUserData() -> UserData {
        if let savedData = UserDefaults.standard.data(forKey: userDataKey),
           let userData = try? JSONDecoder().decode(UserData.self, from: savedData) {
            return userData
        }
        return UserData.defaultData
    }
    
    func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.data(forKey: userDataKey) != nil
    }
}
