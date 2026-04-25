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
        VStack(spacing: 12) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(ZuroxiaTheme.borderFaint, lineWidth: 1)
                
                // Inner dashed ring
                Circle()
                    .strokeBorder(ZuroxiaTheme.borderLight, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .padding(6)
                
                // Active value ring
                Circle()
                    .trim(from: 0, to: min(value, 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 2, lineCap: .square)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6, bounce: 0.15), value: value)
                    .cyberGlow(color: color)
                    .padding(12)

                VStack(spacing: 2) {
                    Text(FormatHelpers.percentInt(value))
                        .font(ZuroxiaTheme.font(24, weight: .light))
                        .contentTransition(.numericText())
                    
                    Text("SYS")
                        .font(ZuroxiaTheme.font(8, weight: .bold))
                        .tracking(3.0)
                        .foregroundStyle(color.opacity(0.8))
                }
            }
            .frame(width: 100, height: 100)

            Text(title.uppercased())
                .font(ZuroxiaTheme.font(9, weight: .medium))
                .tracking(2.0)
                .foregroundStyle(.gray)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(FormatHelpers.percentInt(value))
        .accessibilityAddTraits(.updatesFrequently)
    }
}
