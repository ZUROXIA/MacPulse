import SwiftUI

public struct GaugeView: View {
    public let title: String
    public let value: Double
    public let color: Color

    public init(title: String, value: Double, color: Color) {
        self.title = title
        self.value = value
        self.color = color
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(value, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: value)
                Text(FormatHelpers.percentInt(value))
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            }
            .frame(width: 80, height: 80)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(FormatHelpers.percentInt(value))
        .accessibilityAddTraits(.updatesFrequently)
    }
}
