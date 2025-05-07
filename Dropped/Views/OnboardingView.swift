//
//  OnboardingView.swift
//  Dropped
//
//  Created on 5/2/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var hasCompletedOnboarding: Bool
    @State private var showingFTPInfo = false
    
    // Colors
    private let cardBackground = Color(.systemBackground)
    private let accentGradient = LinearGradient(
        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerView
                    
                    // Unit Selection
                    unitSelectionView
                    
                    // Personal Metrics
                    personalMetricsView
                    
                    // Training Plan
                    trainingPlanView
                    
                    // Generate Plan Button
                    generatePlanButton
                    
                    Spacer(minLength: 30)
                }
                .padding()
            }
            .navigationTitle("Dropped")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "bicycle")
                            .font(.headline)
                        Text("Dropped")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .overlay {
                if showingFTPInfo {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay {
                            InfoPopupView(
                                title: "What is FTP?",
                                message: "Functional Threshold Power (FTP) is the maximum power you can sustain for an hour. It's used to set your training zones and personalize your workouts.\n\nIf you don't know your FTP, enter an estimate based on your fitness level:\n• Beginner: 120-150 watts\n• Intermediate: 150-220 watts\n• Advanced: 220+ watts",
                                isPresented: $showingFTPInfo
                            )
                        }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: showingFTPInfo)
        }
    }
    
    // Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Let's Get Started")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Set up your profile to create a personalized training plan")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    // Unit Selection View
    private var unitSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurement Units")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            
            HStack(spacing: 12) {
                // Imperial button
                Button(action: {
                    if viewModel.isMetric {
                        viewModel.toggleUnitSystem()
                    }
                }) {
                    UnitButton(
                        text: "Imperial",
                        isSelected: !viewModel.isMetric,
                        icon: "rulers"
                    )
                }
                
                // Metric button
                Button(action: {
                    if !viewModel.isMetric {
                        viewModel.toggleUnitSystem()
                    }
                }) {
                    UnitButton(
                        text: "Metric",
                        isSelected: viewModel.isMetric,
                        icon: "scalemass"
                    )
                }
            }
            
            // Weight unit refinement if in imperial mode
            if !viewModel.isMetric && viewModel.showStonesOption {
                HStack(spacing: 12) {
                    Text("Weight Unit:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Weight Unit", selection: $viewModel.selectedWeightUnit) {
                        Text("Pounds (lb)").tag(WeightUnit.pounds)
                        Text("Stones (st)").tag(WeightUnit.stones)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.selectedWeightUnit) { newUnit in
                        viewModel.selectWeightUnit(newUnit)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // Personal Metrics View
    private var personalMetricsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personal Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            // Weight
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Weight")
                        .font(.headline)
                    
                    Text("(\(viewModel.selectedWeightUnit.rawValue))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                CustomTextField(
                    text: $viewModel.weight,
                    placeholder: "Enter your weight",
                    keyboardType: .decimalPad,
                    error: viewModel.weightError
                )
            }
            
            // FTP
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FTP")
                        .font(.headline)
                    
                    Text("(watts)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingFTPInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                CustomTextField(
                    text: $viewModel.ftp,
                    placeholder: "Enter your FTP",
                    keyboardType: .numberPad,
                    error: viewModel.ftpError
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // Training Plan View
    private var trainingPlanView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Training Plan")
                .font(.title2)
                .fontWeight(.bold)
            
            // Hours per week
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Hours per week")
                        .font(.headline)
                    
                    Text("(1-40)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                CustomTextField(
                    text: $viewModel.trainingHoursPerWeek,
                    placeholder: "Available training hours",
                    keyboardType: .numberPad,
                    error: viewModel.hoursError
                )
            }
            
            // Training Goal
            VStack(alignment: .leading, spacing: 12) {
                Text("Training Goal")
                    .font(.headline)
                
                VStack(spacing: 10) {
                    ForEach(TrainingGoal.allCases) { goal in
                        Button(action: {
                            viewModel.selectedGoal = goal
                        }) {
                            GoalCard(goal: goal, isSelected: viewModel.selectedGoal == goal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // Generate Plan Button
    private var generatePlanButton: some View {
        Button(action: {
            if viewModel.saveUserData() {
                hasCompletedOnboarding = true
            }
        }) {
            HStack {
                Spacer()
                Text("Generate Training Plan")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
            .background(accentGradient)
            .cornerRadius(12)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 16)
    }
}

// MARK: - Supporting Views

struct UnitButton: View {
    let text: String
    let isSelected: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .accentColor)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.clear, 
                        radius: 3, x: 0, y: 2)
        )
        .foregroundColor(isSelected ? .white : .primary)
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(error != nil ? Color.red : Color.clear, lineWidth: 1)
                )
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

struct GoalCard: View {
    let goal: TrainingGoal
    let isSelected: Bool
    
    // Icon for each goal
    private var goalIcon: String {
        switch goal {
        case .getFaster:
            return "speedometer"
        case .haveFun:
            return "heart.fill"
        case .loseWeight:
            return "figure.walk"
        case .buildEndurance:
            return "infinity"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: goalIcon)
                .font(.title3)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 30)
            
            Text(goal.rawValue)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color(.systemGray6) : Color(.systemGray5).opacity(0.5))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.2) : Color.clear, 
                        radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
