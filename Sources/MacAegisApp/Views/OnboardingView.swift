import SwiftUI
import AppKit
import MacAegisCore

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var isHoveringSettings = false
    @State private var isHoveringSkip = false
    @State private var isChecking = false

    var body: some View {
        ZStack {
            // Cosmic Background
            Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 46))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                
                // Text
                VStack(spacing: 12) {
                    Text(l10n("解锁深度清理权限", "Unlock Full Deep Clean"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(l10n("为了彻底定位并粉碎受 macOS TCC 保护的深层沙盒残留，MacAegis 需要完全磁盘访问权限 (FDA)。\\n如果不授权，引擎将运行在受限模式下，无法清理核心容器残留。", "To eradicate deeply hidden macOS sandbox leftovers, MacAegis requires Full Disk Access (FDA).\\nWithout it, the engine will run in restricted mode and cannot clean core containers."))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        openSystemSettings()
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text(l10n("前往系统设置授权", "Grant Access in Settings"))
                                .fontWeight(.medium)
                        }
                        .frame(width: 240, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: isHoveringSettings ? [.blue, .purple] : [.blue.opacity(0.8), .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringSettings = $0 }
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            checkFDAStatus()
                        }) {
                            Text(isChecking ? l10n("检查中...", "Checking...") : l10n("我已授权，重新检查", "I've granted it, check again"))
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        
                        Text("|").foregroundColor(.white.opacity(0.3))
                        
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            Text(l10n("暂不授权 (受限模式)", "Skip (Restricted Mode)"))
                                .font(.system(size: 13))
                                .foregroundColor(isHoveringSkip ? .white : .white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .onHover { isHoveringSkip = $0 }
                    }
                }
                .padding(.top, 10)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkFDAStatus() {
        isChecking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let tccPath = NSHomeDirectory() + "/Library/Application Support/com.apple.TCC"
            let hasFDA = (try? FileManager.default.contentsOfDirectory(atPath: tccPath)) != nil
            isChecking = false
            if hasFDA {
                withAnimation(.easeOut(duration: 0.3)) {
                    isPresented = false
                }
            } else {
                // Give a subtle shake or feedback here if needed, but visual checking is enough for now.
                NSSound.beep()
            }
        }
    }
}
