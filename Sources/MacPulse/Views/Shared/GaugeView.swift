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
                    .stroke(color.opacity(0.12), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: min(value, 1.0))
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0.6), color],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * min(value, 1.0))
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6, bounce: 0.15), value: value)

                Text(FormatHelpers.percentInt(value))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
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
