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
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
            Text(title)
                .font(.headline)
        }
    }
}
