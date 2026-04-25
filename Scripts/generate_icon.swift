#!/usr/bin/env swift
import AppKit

func generateIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let s = CGFloat(size)
    let ctx = NSGraphicsContext.current!.cgContext

    // Background: rounded rect with gradient
    let cornerRadius = s * 0.2
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let bgGradient = NSGradient(colors: [
        NSColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0),
        NSColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0),
    ])!
    bgGradient.draw(in: bgPath, angle: -90)

    // Draw gauge arc (background)
    let center = CGPoint(x: s / 2, y: s * 0.48)
    let radius = s * 0.32
    let lineWidth = s * 0.06

    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.15).cgColor)
    ctx.addArc(center: center, radius: radius, startAngle: .pi * 0.8, endAngle: .pi * 0.2, clockwise: true)
    ctx.strokePath()

    // Draw gauge arc (filled — blue to cyan gradient effect via segments)
    let fillAngle = 0.65 // 65% fill
    let startAngle = Double.pi * 0.8
    let endAngle = Double.pi * 0.2
    let totalArc = (2 * Double.pi) - (startAngle - endAngle)
    let segments = 20
    for i in 0..<Int(Double(segments) * fillAngle) {
        let t = Double(i) / Double(segments)
        let a1 = startAngle - t * totalArc
        let a2 = startAngle - (t + 1.0 / Double(segments)) * totalArc

        let r = 0.2 + t * 0.1
        let g = 0.5 + t * 0.3
        let b = 1.0 - t * 0.1
        ctx.setStrokeColor(NSColor(red: r, green: g, blue: b, alpha: 1.0).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)
        ctx.addArc(center: center, radius: radius, startAngle: a1, endAngle: a2, clockwise: true)
        ctx.strokePath()
    }

    // Draw needle
    let needleAngle = startAngle - fillAngle * totalArc
    let needleLen = radius * 0.8
    let needleEnd = CGPoint(
        x: center.x + cos(needleAngle) * needleLen,
        y: center.y + sin(needleAngle) * needleLen
    )
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(s * 0.025)
    ctx.setLineCap(.round)
    ctx.move(to: center)
    ctx.addLine(to: needleEnd)
    ctx.strokePath()

    // Center dot
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - s * 0.03, y: center.y - s * 0.03, width: s * 0.06, height: s * 0.06))

    // "P" text at bottom
    let font = NSFont.systemFont(ofSize: s * 0.16, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let text = "P" as NSString
    let textSize = text.size(withAttributes: attrs)
    text.draw(at: NSPoint(x: (s - textSize.width) / 2, y: s * 0.08), withAttributes: attrs)

    image.unlockFocus()
    return image
}

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let outputDir = "Resources/AppIcon.appiconset"

for size in sizes {
    let image = generateIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(size)px icon")
        continue
    }
    let path = "\(outputDir)/icon_\(size).png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("Generated \(path)")
}

print("Done!")
