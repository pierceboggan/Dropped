//
//  HealthKitService.swift
//  Dropped
//
//  Wraps HealthKit for reading rider metrics and writing completed cycling workouts.
//  Protocol-based so tests can stub the integration without touching HKHealthStore.
//

import Foundation
#if canImport(HealthKit) && !os(macOS)
import HealthKit
#endif

// MARK: - Value types

/// Snapshot of a completed cycling workout for persistence to HealthKit.
struct CompletedWorkoutSummary: Equatable {
    let start: Date
    let end: Date
    /// Optional override for kcal burned. When nil, the service estimates from `averagePowerWatts`
    /// using a typical cycling gross efficiency.
    let totalEnergyKilocalories: Double?
    let averageHeartRate: Double?
    let averagePowerWatts: Int?
    let distanceMeters: Double?
    let isIndoor: Bool

    init(start: Date,
         end: Date,
         totalEnergyKilocalories: Double? = nil,
         averageHeartRate: Double? = nil,
         averagePowerWatts: Int? = nil,
         distanceMeters: Double? = nil,
         isIndoor: Bool = true) {
        self.start = start
        self.end = end
        self.totalEnergyKilocalories = totalEnergyKilocalories
        self.averageHeartRate = averageHeartRate
        self.averagePowerWatts = averagePowerWatts
        self.distanceMeters = distanceMeters
        self.isIndoor = isIndoor
    }

    var duration: TimeInterval { end.timeIntervalSince(start) }

    /// Estimate metabolic active kcal from average mechanical power.
    /// Uses gross cycling efficiency of ~23% (typical range 20–25%):
    ///   metabolicJoules = (watts × seconds) / 0.23
    ///   kcal = metabolicJoules / 4184
    /// HealthKit's `activeEnergyBurned` expects metabolic kcal, not mechanical work.
    static func estimateKilocalories(averagePowerWatts: Int, duration: TimeInterval) -> Double {
        guard averagePowerWatts > 0, duration > 0 else { return 0 }
        let mechanicalJoules = Double(averagePowerWatts) * duration
        let metabolicJoules = mechanicalJoules / 0.23
        return metabolicJoules / 4184.0
    }
}

enum HealthKitServiceError: Error, Equatable {
    case unavailable
    case notAuthorized
    case underlying(String)
}

// MARK: - Protocol

protocol HealthKitServicing {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func latestBodyMassKg() async throws -> (mass: Double, date: Date)?
    func latestRestingHeartRate() async throws -> Double?
    func latestVO2Max() async throws -> Double?
    func latestCyclingFTP() async throws -> Int?
    func saveCyclingWorkout(_ summary: CompletedWorkoutSummary) async throws
}

// MARK: - Default implementation

final class HealthKitService: HealthKitServicing {
    static let shared = HealthKitService()

    #if canImport(HealthKit) && !os(macOS)
    private let store = HKHealthStore()
    #endif

    init() {}

    var isAvailable: Bool {
        #if canImport(HealthKit) && !os(macOS)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    func requestAuthorization() async throws {
        #if canImport(HealthKit) && !os(macOS)
        guard isAvailable else { throw HealthKitServiceError.unavailable }
        var read: Set<HKObjectType> = []
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            read.insert(bodyMass)
        }
        if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            read.insert(restingHR)
        }
        if let vo2 = HKObjectType.quantityType(forIdentifier: .vo2Max) {
            read.insert(vo2)
        }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) {
            read.insert(hr)
        }
        if #available(iOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, *) {
            if let ftp = HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower) {
                read.insert(ftp)
            }
        }
        var write: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            write.insert(energy)
        }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) {
            write.insert(hr)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceCycling) {
            write.insert(distance)
        }
        try await store.requestAuthorization(toShare: write, read: read)
        #else
        throw HealthKitServiceError.unavailable
        #endif
    }

    func latestBodyMassKg() async throws -> (mass: Double, date: Date)? {
        #if canImport(HealthKit) && !os(macOS)
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        guard let sample = try await latestSample(of: type) else { return nil }
        let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        return (kg, sample.endDate)
        #else
        return nil
        #endif
    }

    func latestRestingHeartRate() async throws -> Double? {
        #if canImport(HealthKit) && !os(macOS)
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        guard let sample = try await latestSample(of: type) else { return nil }
        let bpm = HKUnit.count().unitDivided(by: .minute())
        return sample.quantity.doubleValue(for: bpm)
        #else
        return nil
        #endif
    }

    func latestVO2Max() async throws -> Double? {
        #if canImport(HealthKit) && !os(macOS)
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return nil }
        guard let sample = try await latestSample(of: type) else { return nil }
        // mL/(kg·min)
        let unit = HKUnit.literUnit(with: .milli)
            .unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        return sample.quantity.doubleValue(for: unit)
        #else
        return nil
        #endif
    }

    func latestCyclingFTP() async throws -> Int? {
        #if canImport(HealthKit) && !os(macOS)
        guard isAvailable else { return nil }
        if #available(iOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, *) {
            guard let type = HKQuantityType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower) else {
                return nil
            }
            guard let sample = try await latestSample(of: type) else { return nil }
            return Int(sample.quantity.doubleValue(for: .watt()).rounded())
        }
        return nil
        #else
        return nil
        #endif
    }

    func saveCyclingWorkout(_ summary: CompletedWorkoutSummary) async throws {
        #if canImport(HealthKit) && !os(macOS)
        guard isAvailable else { throw HealthKitServiceError.unavailable }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = summary.isIndoor ? .indoor : .outdoor

        let builder = HKWorkoutBuilder(healthStore: store,
                                       configuration: configuration,
                                       device: .local())
        try await builder.beginCollection(at: summary.start)

        let kcal = summary.totalEnergyKilocalories
            ?? CompletedWorkoutSummary.estimateKilocalories(
                averagePowerWatts: summary.averagePowerWatts ?? 0,
                duration: summary.duration
            )

        var samples: [HKSample] = []
        if kcal > 0,
           let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
            samples.append(HKQuantitySample(type: energyType,
                                            quantity: quantity,
                                            start: summary.start,
                                            end: summary.end))
        }
        if let hr = summary.averageHeartRate, hr > 0,
           let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let bpm = HKUnit.count().unitDivided(by: .minute())
            let quantity = HKQuantity(unit: bpm, doubleValue: hr)
            samples.append(HKQuantitySample(type: hrType,
                                            quantity: quantity,
                                            start: summary.start,
                                            end: summary.end))
        }
        if let meters = summary.distanceMeters, meters > 0,
           let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceCycling) {
            let quantity = HKQuantity(unit: .meter(), doubleValue: meters)
            samples.append(HKQuantitySample(type: distanceType,
                                            quantity: quantity,
                                            start: summary.start,
                                            end: summary.end))
        }
        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }

        try await builder.endCollection(at: summary.end)
        _ = try await builder.finishWorkout()
        #else
        throw HealthKitServiceError.unavailable
        #endif
    }

    // MARK: - Helpers

    #if canImport(HealthKit) && !os(macOS)
    private func latestSample(of type: HKQuantityType) async throws -> HKQuantitySample? {
        try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type,
                                      predicate: nil,
                                      limit: 1,
                                      sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitServiceError.underlying(error.localizedDescription))
                    return
                }
                continuation.resume(returning: samples?.first as? HKQuantitySample)
            }
            store.execute(query)
        }
    }
    #endif
}

// MARK: - Profile sync helper

extension HealthKitServicing {
    /// Pull the latest body mass from HealthKit and apply to the user profile if newer.
    /// Returns true when a profile update occurred.
    @discardableResult
    func syncBodyMassToProfile(using manager: UserDataManager = .shared) async -> Bool {
        guard isAvailable else { return false }
        guard let latest = try? await latestBodyMassKg() else { return false }
        return manager.updateWeightFromHealth(kg: latest.mass, sampleDate: latest.date)
    }
}
