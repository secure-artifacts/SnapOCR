import Foundation
import Cocoa
import Vision

class OCRManager {
    static let shared = OCRManager()
    
    // 获取当前设备 Vision 框架支持识别的所有语言列表
    static func getSupportedLanguages() -> [String] {
        let request = VNRecognizeTextRequest()
        return (try? request.supportedRecognitionLanguages()) ?? ["zh-Hans", "en-US"]
    }

    // 获取默认识别语言
    static func getDefaultLanguage() -> String {
        let supported = getSupportedLanguages()
        if let preferred = Locale.preferredLanguages.first,
           let matched = Bundle.preferredLocalizations(from: supported, forPreferences: [preferred]).first {
            return matched
        }
        return supported.first ?? "en-US"
    }
    
    // 截图流程
    func takeScreenshotAndProcess() {
        // 检查是否有权限
        if !checkScreenRecordingPermission() {
            requestScreenRecordingPermission()
            return
        }
        
        // 调用系统截图
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        
        // 截图完成后回调
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                // 获取截图的图片数据
                if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                    self.recognizeText(from: image)
                }
            }
        }
        task.launch()
    }
    
    // OCR 识别
    private func recognizeText(from image: NSImage) {
        // 将 NSImage 转换为 Vision 框架支持的 CIImage 格式
        guard let tiffData = image.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else { return }
        
        // 创建图像请求处理器
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // 创建 OCR 请求
        let request = VNRecognizeTextRequest { request, _ in
            // 获取识别结果
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else { return }
            
            // 读取设置中是否开启了“保留换行”
            let keepLineBreaks = UserDefaults.standard.bool(forKey: "keepLineBreaks")
            // let separator = keepLineBreaks ? "\n" : " "
            
            // 提取识别到的文字
            // 如果不保留换行，把换行符替换为空格
            let recognizedString = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: keepLineBreaks ? "\n" : " ")
            
            // 弹出 Toast 提示
            if !recognizedString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.copyToPasteboard(text: recognizedString)
                DispatchQueue.main.async {
                    ToastWindowController.shared.showToast(message: "复制到剪贴板", icon: "👍")
                }
            }
        }
        
        // 配置 OCR 请求参数
        let lang = UserDefaults.standard.string(forKey: "ocrLanguage") ?? OCRManager.getDefaultLanguage()
        request.recognitionLanguages = [lang] // 设置识别语言
        request.recognitionLevel = .accurate
        // 自动纠正
        request.usesLanguageCorrection = true
        
        // 执行 OCR 任务
        try? handler.perform([request])
    }
    
    // 写入剪切板
    private func copyToPasteboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // 检测是否有屏幕录制权限
    private func checkScreenRecordingPermission() -> Bool {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]
        return windows != nil && !windows!.isEmpty
    }

    // 请求权限
    private func requestScreenRecordingPermission() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "需要屏幕录制权限"
            alert.informativeText = "MiniSniper 需要屏幕录制权限才能进行截图识别。\n\n请在系统设置中授予权限：\n系统设置 > 隐私与安全性 > 屏幕录制"
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "取消")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            }
        }
    }
}
