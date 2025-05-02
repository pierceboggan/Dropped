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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Metrics")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Weight (kg)")
                                .font(.headline)
                            Spacer()
                            TextField("Weight", text: $viewModel.weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        if let error = viewModel.weightError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("FTP (watts)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Button(action: {
                                showingFTPInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Spacer()
                            
                            TextField("FTP", text: $viewModel.ftp)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        if let error = viewModel.ftpError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Training Plan")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Hours per week")
                                .font(.headline)
                            Spacer()
                            TextField("Hours", text: $viewModel.trainingHoursPerWeek)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        if let error = viewModel.hoursError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Training Goal")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Picker("Training Goal", selection: $viewModel.selectedGoal) {
                            ForEach(TrainingGoal.allCases) { goal in
                                Text(goal.rawValue).tag(goal)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section {
                    Button(action: {
                        if viewModel.saveUserData() {
                            hasCompletedOnboarding = true
                        }
                    }) {
                        Text("Generate Training Plan")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .padding()
                }
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
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
