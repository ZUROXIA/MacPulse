import SwiftUI

/// A tiny graph for the menu bar label, showing CPU usage trend.
public struct MenuBarGraphView: View {
    public let data: [Double]
    public let color: Color

    public init(data: [Double], color: Color = .blue) {
        self.data = data
        self.color = color
    }

    public var body: some View {
        Canvas { context, size in
            guard data.count >= 2 else { return }

            let step = size.width / CGFloat(data.count - 1)

            var path = Path()
            for (i, value) in data.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height - (CGFloat(min(value, 1.0)) * size.height)
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path, with: .color(color), lineWidth: 1)

            // Fill
            var fillPath = path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()
            context.fill(fillPath, with: .color(color.opacity(0.3)))
        }
        .frame(width: 32, height: 12)
    }
}
