//
//  UserData.swift
//  Dropped
//
//  Created on 5/2/25.
//

import Foundation

enum TrainingGoal: String, CaseIterable, Identifiable {
    case getFaster = "Get Faster"
    case haveFun = "Have Fun"
    case loseWeight = "Lose Weight"
    case buildEndurance = "Build Endurance"
    
    var id: String { self.rawValue }
}

struct UserData: Codable {
    var weight: Double
    var ftp: Int
    var trainingHoursPerWeek: Int
    var trainingGoal: String
    
    static let defaultData = UserData(weight: 70.0, ftp: 200, trainingHoursPerWeek: 5, trainingGoal: TrainingGoal.haveFun.rawValue)
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
