//
//  InfoPopupView.swift
//  Dropped
//
//  Created on 5/2/25.
//

import SwiftUI

struct InfoPopupView: View {
    let title: String
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
            
            Button("Got it") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(radius: 20)
        .padding(30)
    }
}

#Preview {
    InfoPopupView(
        title: "What is FTP?",
        message: "Functional Threshold Power (FTP) is the maximum power you can sustain for an hour. It's used to set your training zones and personalize your workouts.",
        isPresented: .constant(true)
    )
    .preferredColorScheme(.dark)
}
