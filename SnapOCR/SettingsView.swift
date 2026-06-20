import SwiftUI
import ServiceManagement
import KeyboardShortcuts

struct SettingsView: View {
    // 初始化状态属性
    @AppStorage("ocrLanguage") private var ocrLanguage = ""
    @AppStorage("keepLineBreaks") private var keepLineBreaks = true
    @AppStorage("autoOpenLinks") private var autoOpenLinks = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    // 获取系统支持的语言列表
    let supportedLanguages = OCRManager.getSupportedLanguages()

    var body: some View {
        Form {
            Section {
                Picker("recognition_language", selection: $ocrLanguage) {
                    ForEach(supportedLanguages, id: \.self) { langCode in
                        // 使用系统语言显示多语言
                        Text(displayName(for: langCode))
                            .tag(langCode)
                    }
                }
                Toggle("keep_line_breaks", isOn: $keepLineBreaks)
                Toggle("auto_open_links", isOn: $autoOpenLinks)
            } header: {
                Label("general", systemImage: "gearshape")
            }

            Section {
                HStack {
                    Text("recognition_shortcuts")
                    Spacer()
                    // 显示设置的快捷键
                    KeyboardShortcuts.Recorder(for: .ocrShortcut)
                }
            } header: {
                Label("shortcuts", systemImage: "keyboard")
            }

            Section {
                Toggle("launch_at_login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        toggleLaunchAtLogin(enabled: newValue)
                    }
            } header: {
                Label("system", systemImage: "laptopcomputer")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 450, height: 420)
        .onAppear {
            // 如果第一次使用，根据系统环境设置默认语言
            if ocrLanguage.isEmpty {
                ocrLanguage = OCRManager.getDefaultLanguage()
            }
        }
    }

    // 使用系统语言显示多语言
    private func displayName(for langCode: String) -> String {
        let locale = Locale(identifier: langCode)
        if let name = locale.localizedString(forIdentifier: langCode) {
            return name.capitalized(with: locale)
        }
        return langCode
    }

    // 开机启动逻辑
    private func toggleLaunchAtLogin(enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled { try service.register() }
            else { try service.unregister() }
        } catch {
            print("设置失败: \(error.localizedDescription)")
        }
    }
}
