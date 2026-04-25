import SwiftUI

public struct SectionHeader: View {
    public let title: String
    public let icon: String
    public let color: Color

    public init(_ title: String, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 14, weight: .light))
                .cyberGlow(color: color)
            
            Text(title.uppercased())
                .font(ZuroxiaTheme.font(10, weight: .medium))
                .tracking(2.0)
                .foregroundStyle(.gray)
            
            Spacer()
        }
        .padding(.bottom, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(ZuroxiaTheme.borderFaint),
            alignment: .bottom
        )
    }
}
