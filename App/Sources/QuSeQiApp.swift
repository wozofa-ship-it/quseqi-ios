import SwiftUI
import WebKit

@main
struct QuSeQiApp: App {
    var body: some Scene {
        WindowGroup {
            WebViewContainer()
                .ignoresSafeArea()
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.add(context.coordinator, name: "quSeQiBackup")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.bounces = false
        context.coordinator.webView = webView

        if let fileURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "quSeQiBackup", let json = message.body as? String else { return }
            // 解析是否为自动备份
            var isAuto = false
            if let data = json.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let mode = obj["mode"] as? String, mode == "auto" {
                isAuto = true
            }
            let ok = saveBackup(json, auto: isAuto)
            let js = "window.quSeQiBackupResult && window.quSeQiBackupResult(\(ok ? "true" : "false"))"
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        private func saveBackup(_ json: String, auto: Bool) -> Bool {
            let fm = FileManager.default
            guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
            let folder = docs.appendingPathComponent("涂料配色")
            do {
                try fm.createDirectory(at: folder, withIntermediateDirectories: true)
                let filename: String
                if auto {
                    // 自动备份：固定文件名，覆盖写入
                    filename = "调色记录-自动备份.json"
                } else {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "yyyyMMdd-HHmmss"
                    filename = "手动调色记录-\(fmt.string(from: Date())).json"
                }
                let url = folder.appendingPathComponent(filename)
                try json.write(to: url, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        }
    }
}
