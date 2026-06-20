import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // 设置初始默认快捷键为 Shift + Command + 2
    static let ocrShortcut = Self("ocrShortcut", default: .init(.two, modifiers: [.command, .shift]))
}
