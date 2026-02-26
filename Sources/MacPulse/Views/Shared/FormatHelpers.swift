import Foundation

public enum FormatHelpers {
    private static let byteFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    public static func bytes(_ value: UInt64) -> String {
        byteFormatter.string(fromByteCount: Int64(value))
    }

    public static func bytesPerSecond(_ value: Double) -> String {
        byteFormatter.string(fromByteCount: Int64(value)) + "/s"
    }

    public static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    public static func percentInt(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    public static func duration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}
