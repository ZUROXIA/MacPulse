import Foundation
import SwiftUI

public enum FanProfile: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case silent = "Silent"
    case balanced = "Balanced"
    case performance = "Performance"
    case custom = "Custom"

    public var id: String { rawValue }

    /// Returns the target RPM for the given fan, or nil for auto/custom (handled separately).
    public func targetRPM(minRPM: Int, maxRPM: Int) -> Int? {
        let range = maxRPM - minRPM
        switch self {
        case .auto: return nil
        case .silent: return minRPM
        case .balanced: return minRPM + Int(Double(range) * 0.4)
        case .performance: return minRPM + Int(Double(range) * 0.8)
        case .custom: return nil
        }
    }

    public var noiseEstimate: String {
        switch self {
        case .auto: "System managed"
        case .silent: "Quiet"
        case .balanced: "Moderate"
        case .performance: "Loud"
        case .custom: "Varies"
        }
    }

    public var color: Color {
        switch self {
        case .auto: .gray
        case .silent: .green
        case .balanced: .blue
        case .performance: .red
        case .custom: .purple
        }
    }

    public static func shouldAutoSwitchToPerformance(
        thermalLevel: ThermalLevel,
        currentProfile: FanProfile,
        alreadyOverridden: Bool
    ) -> Bool {
        guard !alreadyOverridden else { return false }
        guard thermalLevel == .serious || thermalLevel == .critical else { return false }
        return currentProfile != .performance && currentProfile != .custom
    }
}
