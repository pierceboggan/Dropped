//
//  PowerZonesView.swift
//  Dropped
//

import SwiftUI

/// Displays Coggan power zones (Z1–Z7) with %FTP ranges and target wattages
/// for the rider's current FTP.
struct PowerZonesView: View {
    @State private var userData: UserData = UserDataManager.shared.loadUserData()

    private var zones: PowerZones { userData.powerZones }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard

                VStack(spacing: 10) {
                    ForEach(zones.all) { zone in
                        PowerZoneRow(
                            zone: zone,
                            wattRange: zones.wattRangeDescription(for: zone)
                        )
                    }
                }
                .padding(.horizontal)

                NavigationLink(destination: FTPTestsView()) {
                    HStack {
                        Image(systemName: "bolt.heart")
                        Text("Take an FTP test")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(Color.accentColor.gradient)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer(minLength: 24)
            }
            .padding(.top)
        }
        .navigationTitle("Power Zones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            userData = UserDataManager.shared.loadUserData()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current FTP")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(userData.ftp) W")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Zones use Coggan's classic seven-zone model.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

private struct PowerZoneRow: View {
    let zone: PowerZone
    let wattRange: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(zone.color)
                .frame(width: 6, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(zone.shortLabel)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text(zone.name)
                        .font(.headline)
                }
                Text(zone.percentRangeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(wattRange)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(zone.shortLabel) \(zone.name), \(zone.percentRangeDescription) of FTP, \(wattRange)")
    }
}
