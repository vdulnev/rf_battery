import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let lastStatusKey = "lastStatus"

    private let monitor = KeychronMonitor()
    private var statusItem: NSStatusItem!
    private var status: MouseStatus?
    private var dongles = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status = loadStatus()

        monitor.onStatus = { [weak self] status in
            self?.status = status
            self?.saveStatus(status)
            self?.refresh()
        }
        monitor.onDevicesChanged = { [weak self] count in
            self?.dongles = count
            self?.refresh()
        }
        monitor.start()

        // Keep the "updated … ago" text fresh.
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        refresh()
    }

    private func refresh() {
        guard let button = statusItem.button else { return }
        let symbol = NSImage(systemSymbolName: symbolName(), accessibilityDescription: "Mouse battery")
        symbol?.isTemplate = true
        button.image = symbol
        button.imagePosition = .imageLeading
        button.title = status.map { " \($0.percent)%" } ?? " –"
        button.appearsDisabled = dongles == 0
        statusItem.menu = buildMenu()
    }

    private func symbolName() -> String {
        guard let status else { return "computermouse" }
        if status.charging { return "battery.100percent.bolt" }
        switch status.percent {
        case 88...: return "battery.100percent"
        case 63..<88: return "battery.75percent"
        case 38..<63: return "battery.50percent"
        case 13..<38: return "battery.25percent"
        default: return "battery.0percent"
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        func info(_ title: String) {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        info("Keychron mouse")
        if let status {
            info("Battery: \(status.percent)%\(status.charging ? " (charging)" : "")")
            let ago = RelativeDateTimeFormatter().localizedString(for: status.updated, relativeTo: Date())
            info("Updated \(ago)")
        } else {
            info("No report yet — press the DPI button")
        }
        if dongles == 0 { info("Dongle not detected") }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private func loadStatus() -> MouseStatus? {
        guard let data = UserDefaults.standard.data(forKey: Self.lastStatusKey) else { return nil }
        return try? JSONDecoder().decode(MouseStatus.self, from: data)
    }

    private func saveStatus(_ status: MouseStatus) {
        if let data = try? JSONEncoder().encode(status) {
            UserDefaults.standard.set(data, forKey: Self.lastStatusKey)
        }
    }
}
