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

    public static func duration(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
