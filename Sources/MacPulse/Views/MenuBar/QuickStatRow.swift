import SwiftUI

public struct QuickStatRow: View {
    public let icon: String
    public let label: String
    public let value: String
    public var color: Color = .primary
    public var sparklineData: [Double]? = nil

    @State private var isHovered = false

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
                .contentTransition(.numericText())
        }
        .font(.system(.body, design: .rounded))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            isHovered
                ? Color.primary.opacity(0.06)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(spokenValue)
    }

    private var spokenValue: String {
        value
            .replacingOccurrences(of: "\u{2191}", with: "upload ")
            .replacingOccurrences(of: "\u{2193}", with: "download ")
    }
}
