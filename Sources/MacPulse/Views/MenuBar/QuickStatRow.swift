import SwiftUI

public struct QuickStatRow: View {
    public let icon: String
    public let label: String
    public let value: String
    public var color: Color = ZuroxiaTheme.textPrimary
    public var sparklineData: [Double]? = nil

    @State private var isHovered = false

    public init(icon: String, label: String, value: String, color: Color = ZuroxiaTheme.textPrimary, sparklineData: [Double]? = nil) {
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
                .cyberGlow(color: color)
                
            Text(label)
                .font(ZuroxiaTheme.font(10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(ZuroxiaTheme.textSecondary)
                
            Spacer()
            
            if let data = sparklineData, data.count >= 2 {
                SparklineView(data: data, color: color)
            }
            
            Text(value)
                .font(ZuroxiaTheme.font(12, weight: .bold))
                .foregroundStyle(ZuroxiaTheme.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isHovered
                ? ZuroxiaTheme.borderFaint
                : ZuroxiaTheme.bgPanel,
            in: RoundedRectangle(cornerRadius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isHovered ? ZuroxiaTheme.borderLight : ZuroxiaTheme.borderFaint, lineWidth: 1)
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
