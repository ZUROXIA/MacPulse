import SwiftUI

public struct QuickStatRow: View {
    public let icon: String
    public let label: String
    public let value: String
    public var color: Color = .primary
    public var sparklineData: [Double]? = nil

    public init(icon: String, label: String, value: String, color: Color = .primary, sparklineData: [Double]? = nil) {
        self.icon = icon
        self.label = label
        self.value = value
        self.color = color
        self.sparklineData = sparklineData
    }

    public var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            if let data = sparklineData, data.count >= 2 {
                SparklineView(data: data, color: color)
            }
            Text(value)
                .monospacedDigit()
                .fontWeight(.medium)
        }
        .font(.system(.body, design: .rounded))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(spokenValue)
    }

    /// Replace Unicode arrows with spoken text for VoiceOver.
    private var spokenValue: String {
        value
            .replacingOccurrences(of: "\u{2191}", with: "upload ")
            .replacingOccurrences(of: "\u{2193}", with: "download ")
    }
}
