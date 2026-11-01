import Foundation
import IOKit.hid
import os

private let log = Logger(subsystem: "com.vd.rfbattery", category: "hid")

/// Battery status of a Keychron mouse as last reported through a Keychron Link dongle.
struct MouseStatus: Codable, Equatable {
    var percent: Int
    var charging: Bool
    var connected: Bool
    var updated: Date
}

/// Listens to the vendor interface (usage page 0x8C) of Keychron Link dongles.
///
/// The dongle refuses feature-report reads on macOS, so the battery cannot be
/// polled. Instead the mouse pushes a status report whenever its state changes
/// (wake, DPI button, polling rate, battery step):
///
///     id 0x54: [0x54, 0xE2, workMode, connect, chargeState, battery%, dpi, rate, ...]
final class KeychronMonitor {
    private static let vendorID = 0x3434
    private static let vendorUsagePage = 0x8C
    private static let statusReportID: UInt32 = 0x54
    private static let statusTag: UInt8 = 0xE2

    var onStatus: ((MouseStatus) -> Void)?
    var onDevicesChanged: ((Int) -> Void)?

    private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    private var deviceCount = 0

    func start() {
        IOHIDManagerSetDeviceMatching(manager, [
            kIOHIDVendorIDKey: Self.vendorID,
            kIOHIDPrimaryUsagePageKey: Self.vendorUsagePage,
        ] as CFDictionary)

        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { ctx, _, _, _ in
            let me = Unmanaged<KeychronMonitor>.fromOpaque(ctx!).takeUnretainedValue()
            me.deviceCount += 1
            log.info("dongle matched, count \(me.deviceCount, privacy: .public)")
            me.onDevicesChanged?(me.deviceCount)
        }, ctx)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { ctx, _, _, _ in
            let me = Unmanaged<KeychronMonitor>.fromOpaque(ctx!).takeUnretainedValue()
            me.deviceCount = max(0, me.deviceCount - 1)
            me.onDevicesChanged?(me.deviceCount)
        }, ctx)
        IOHIDManagerRegisterInputReportCallback(manager, { ctx, _, _, _, reportID, report, length in
            let me = Unmanaged<KeychronMonitor>.fromOpaque(ctx!).takeUnretainedValue()
            me.handle(reportID: reportID, bytes: UnsafeBufferPointer(start: report, count: length))
        }, ctx)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        log.info("IOHIDManagerOpen: \(String(format: "0x%08x", result), privacy: .public)")
    }

    private func handle(reportID: UInt32, bytes: UnsafeBufferPointer<UInt8>) {
        log.debug("report \(reportID, privacy: .public): \(bytes.map { String(format: "%02x", $0) }.joined(separator: " "), privacy: .public)")
        // macOS delivers the report ID as the first byte.
        guard reportID == Self.statusReportID, bytes.count >= 6, bytes[1] == Self.statusTag else { return }
        let percent = Int(bytes[5])
        guard percent <= 100 else { return }
        onStatus?(MouseStatus(
            percent: percent,
            charging: bytes[4] != 0,
            connected: bytes[3] == 1,
            updated: Date()
        ))
    }
}
