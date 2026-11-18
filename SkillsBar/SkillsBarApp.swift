import SwiftUI
import AppKit
import Carbon.HIToolbox

extension Notification.Name {
    static let skillsBarPopoverDidOpen = Notification.Name("SkillsBarPopoverDidOpen")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let store: SkillStore
    private let usageTracker: UsageTracker

    override init() {
        let tracker = UsageTracker()
        self.usageTracker = tracker
        self.store = SkillStore(usageTracker: tracker)
        super.init()
    }
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let index = CommandLine.arguments.firstIndex(of: "--preview-source"), CommandLine.arguments.indices.contains(index + 1),
           ["Gemini", "Codex", "Grok Bot", "WorkBuddy", "收藏夹"].contains(CommandLine.arguments[index + 1]) {
            UserDefaults.standard.set(CommandLine.arguments[index + 1], forKey: "selectedTab")
        }
        if !UserDefaults.standard.bool(forKey: "hasOpenedWorkflowLibrary") {
            UserDefaults.standard.set("收藏夹", forKey: "selectedTab")
            UserDefaults.standard.set(true, forKey: "hasOpenedWorkflowLibrary")
        }
        // Prevent Settings window from appearing on launch
        NSApp.setActivationPolicy(.accessory)

        Task { @MainActor in
            store.start()
            usageTracker.refresh()
            usageTracker.startAutoRefresh()
        }

        // Popover
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        let hosting = NSHostingController(
            rootView: MenuBarView(store: store, usageTracker: usageTracker)
        )
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting

        // Status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = MenuBarIcon.create()
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        if CommandLine.arguments.contains("--show") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.togglePopover(nil) }
        }
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.indices.contains(index + 1) {
            let output = CommandLine.arguments[index + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let view = self?.popover.contentViewController?.view else { return }
                view.layoutSubtreeIfNeeded()
                guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
                view.cacheDisplay(in: view.bounds, to: bitmap)
                if let data = bitmap.representation(using: .png, properties: [:]) { try? data.write(to: URL(fileURLWithPath: output)) }
            }
        }
        // Global hotkey (Option+Shift+S)
        registerGlobalHotkey()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotkeyNotification),
            name: NSNotification.Name("ToggleSkillsBarPopover"),
            object: nil
        )
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NotificationCenter.default.post(name: .skillsBarPopoverDidOpen, object: nil)
        }
    }

    @objc private func handleHotkeyNotification() {
        togglePopover(nil)
    }

    private func registerGlobalHotkey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        var handlerRef: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, _) -> OSStatus in
                NotificationCenter.default.post(
                    name: NSNotification.Name("ToggleSkillsBarPopover"),
                    object: nil
                )
                return noErr
            },
            1,
            &eventType,
            nil,
            &handlerRef
        )
        eventHandler = handlerRef

        let hotKeyID = EventHotKeyID(signature: OSType(0x534B4252), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_S),
            UInt32(optionKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}

enum MenuBarIcon {
    static func create() -> NSImage {
        // Use the system symbol metrics and template rendering so the library
        // mark matches neighbouring menu bar items in light and dark appearances.
        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let image = NSImage(
            systemSymbolName: "infinity",
            accessibilityDescription: "汇芯技能管家"
        )!.withSymbolConfiguration(configuration)!
        image.isTemplate = true
        return image
    }
}
