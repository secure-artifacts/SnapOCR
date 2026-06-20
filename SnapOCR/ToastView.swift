import SwiftUI
import AppKit

class ToastWindowController {
    static let shared = ToastWindowController()
    private var toastWindow: NSWindow?
    
    func showToast(message: String, icon: String = "doc.on.clipboard.fill") {
        // 如果当前已有 Toast，先关闭掉，确保只存在一个提示
        if let oldWindow = toastWindow {
            oldWindow.close()
            toastWindow = nil
        }
        
        // 获取屏幕信息
        guard let screen = NSScreen.main else { return }
        // 获取去掉菜单栏和 Dock 后的区域
        let screenRect = screen.visibleFrame
        
        // Toast 窗口尺寸
        let sideLength: CGFloat = 160
        // 距离屏幕底部的距离
        let bottomPadding: CGFloat = 120
        
        let xPos = screenRect.midX - sideLength / 2
        let yPos = screenRect.minY + bottomPadding
        
        // 创建窗口
        let window = NSPanel(
            contentRect: NSRect(x: xPos, y: yPos, width: sideLength, height: sideLength),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        let contentView = ToastHUDView(message: message, icon: icon)
        window.contentView = NSHostingView(rootView: contentView)
        
        self.toastWindow = window
        // 置顶窗口
        window.orderFrontRegardless()
        
        // 延迟消失逻辑
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.hideToast(window: window)
        }
    }
    
    // 淡出动画和清理窗口
    private func hideToast(window: NSWindow) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5 // 动画时长
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.close() // 动画结束后关闭窗口
            if self.toastWindow == window {
                self.toastWindow = nil
            }
        })
    }
}

// Toast 外观
struct ToastHUDView: View {
    let message: String
    let icon: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            // 图标处理
            Group {
                if icon.contains(".") {
                    Image(systemName: icon)
                        .font(.system(size: 50, weight: .regular))
                } else {
                    Text(icon).font(.system(size: 50))
                }
            }
            .foregroundColor(.primary.opacity(0.8))
            
            // 文本会处理
            Text(message)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 磨砂玻璃效果
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(24)
        .overlay(
            // 增加秒变
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        // 进场动画效果
        .scaleEffect(isAnimating ? 1.0 : 0.85)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                isAnimating = true
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
