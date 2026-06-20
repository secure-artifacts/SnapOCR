import Cocoa
import SwiftUI
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: [
            "keepLineBreaks": true,
            "ocrLanguage": OCRManager.getDefaultLanguage(),
            "launchAtLogin": false,
            "autoOpenLinks": false
        ])
        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            // 设置状态栏图标
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "OCR")
        }
        
        // 加载菜单栏
        constructMenu()
        
        // 注册全局快捷键监听
        KeyboardShortcuts.onKeyUp(for: .ocrShortcut) {
            OCRManager.shared.takeScreenshotAndProcess()
        }
    }

    // 构建状态栏图标点击后弹出的菜单
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: NSLocalizedString("capture_text", comment: ""), action: #selector(startOCR), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: NSLocalizedString("settings", comment: ""), action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("quit", comment: ""), action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        statusItem?.menu = menu
    }

    @objc func startOCR() {
        OCRManager.shared.takeScreenshotAndProcess()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false)
            window.center()
            window.title = NSLocalizedString("settings", comment: "")
            window.contentView = NSHostingView(rootView: contentView)
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
