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
            // Header with title
            HStack {
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, -10)
            
            // Title and message
            VStack(spacing: 16) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // "Got it" button
            Button(action: {
                isPresented = false
            }) {
                Text("Got it")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
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
