import SwiftUI
import AppKit
import Carbon.HIToolbox

extension Notification.Name {
    static let skillsBarPopoverDidOpen = Notification.Name("SkillsBarPopoverDidOpen")
}

@main
struct HuixinSkillsManagerApp: App {
    @StateObject private var store: SkillStore
    @StateObject private var usageTracker: UsageTracker

    init() {
        runCLIArgsIfNeeded()
        let tracker = UsageTracker()
        let skillStore = SkillStore(usageTracker: tracker)
        _usageTracker = StateObject(wrappedValue: tracker)
        _store = StateObject(wrappedValue: skillStore)

        if let index = CommandLine.arguments.firstIndex(of: "--preview-source"), CommandLine.arguments.indices.contains(index + 1),
           ["Gemini", "Codex", "Grok Bot", "WorkBuddy", "收藏夹"].contains(CommandLine.arguments[index + 1]) {
            UserDefaults.standard.set(CommandLine.arguments[index + 1], forKey: "selectedTab")
        }
        if !UserDefaults.standard.bool(forKey: "hasOpenedWorkflowLibrary") {
            UserDefaults.standard.set("收藏夹", forKey: "selectedTab")
            UserDefaults.standard.set(true, forKey: "hasOpenedWorkflowLibrary")
        }

        Task { @MainActor in
            skillStore.start()
            tracker.refresh()
            tracker.startAutoRefresh()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: store, usageTracker: usageTracker)
        } label: {
            Image(nsImage: MenuBarIcon.create())
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerGlobalHotkey()
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
