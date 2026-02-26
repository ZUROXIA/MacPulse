import Foundation
import IOKit

/// Low-level interface to Apple SMC for reading temperature sensors and fan speeds.
public enum SMCHelper {
    // MARK: - SMC Types

    private static let smcService: io_connect_t? = {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != IO_OBJECT_NULL else { return nil }
        var conn: io_connect_t = 0
        let result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        IOObjectRelease(service)
        return result == KERN_SUCCESS ? conn : nil
    }()

    private struct SMCKeyData {
        struct Vers {
            var major: UInt8 = 0
            var minor: UInt8 = 0
            var build: UInt8 = 0
            var reserved: UInt8 = 0
            var release: UInt16 = 0
        }

        struct PLimitData {
            var version: UInt16 = 0
            var length: UInt16 = 0
            var cpuPLimit: UInt32 = 0
            var gpuPLimit: UInt32 = 0
            var memPLimit: UInt32 = 0
        }

        struct KeyInfo {
            var dataSize: UInt32 = 0
            var dataType: UInt32 = 0
            var dataAttributes: UInt8 = 0
        }

        var key: UInt32 = 0
        var vers: Vers = Vers()
        var pLimitData: PLimitData = PLimitData()
        var keyInfo: KeyInfo = KeyInfo()
        var padding: UInt16 = 0
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                     UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                     UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                     UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
            (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    }

    private static let kSMCReadKey: UInt8 = 5
    private static let kSMCGetKeyInfo: UInt8 = 9

    // MARK: - Public API

    /// Read CPU proximity temperature (TC0P) in Celsius.
    public static func readCPUTemperature() -> Double? {
        readTemperature(key: "TC0P")
    }

    /// Read GPU proximity temperature (TG0P) in Celsius.
    public static func readGPUTemperature() -> Double? {
        readTemperature(key: "TG0P")
    }

    /// Read the number of fans.
    public static func readFanCount() -> Int {
        guard let bytes = readSMCKey("FNum") else { return 0 }
        return Int(bytes.0)
    }

    /// Read actual RPM for fan at given index.
    public static func readFanRPM(index: Int) -> Int {
        let key = "F\(index)Ac"
        guard let bytes = readSMCKey(key) else { return 0 }
        // fpe2 format: value = (byte0 << 6) + (byte1 >> 2)
        return (Int(bytes.0) << 6) + (Int(bytes.1) >> 2)
    }

    // MARK: - Private

    private static func readTemperature(key: String) -> Double? {
        guard let bytes = readSMCKey(key) else { return nil }
        // sp78 format: signed 7.8 fixed point
        let raw = (Int16(bytes.0) << 8) | Int16(bytes.1)
        let temp = Double(raw) / 256.0
        // Sanity check
        return (temp > 0 && temp < 150) ? temp : nil
    }

    private static func fourCharCode(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for char in str.utf8.prefix(4) {
            result = (result << 8) | UInt32(char)
        }
        return result
    }

    private static func readSMCKey(_ key: String) -> (UInt8, UInt8)? {
        guard let conn = smcService else { return nil }

        var inputStruct = SMCKeyData()
        var outputStruct = SMCKeyData()

        inputStruct.key = fourCharCode(key)
        inputStruct.data8 = kSMCGetKeyInfo

        var outputSize = MemoryLayout<SMCKeyData>.stride
        var result = IOConnectCallStructMethod(
            conn,
            2, // kSMCHandleYPCEvent
            &inputStruct,
            MemoryLayout<SMCKeyData>.stride,
            &outputStruct,
            &outputSize
        )

        guard result == KERN_SUCCESS else { return nil }

        inputStruct.keyInfo.dataSize = outputStruct.keyInfo.dataSize
        inputStruct.keyInfo.dataType = outputStruct.keyInfo.dataType
        inputStruct.data8 = kSMCReadKey

        outputSize = MemoryLayout<SMCKeyData>.stride
        result = IOConnectCallStructMethod(
            conn,
            2,
            &inputStruct,
            MemoryLayout<SMCKeyData>.stride,
            &outputStruct,
            &outputSize
        )

        guard result == KERN_SUCCESS else { return nil }

        return (outputStruct.bytes.0, outputStruct.bytes.1)
    }
}
