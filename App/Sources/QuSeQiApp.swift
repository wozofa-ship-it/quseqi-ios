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
            let ok = saveBackup(json)
            let js = "window.quSeQiBackupResult && window.quSeQiBackupResult(\(ok ? "true" : "false"))"
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        private func saveBackup(_ json: String) -> Bool {
            let fm = FileManager.default
            guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
            let folder = docs.appendingPathComponent("取色器备份")
            do {
                try fm.createDirectory(at: folder, withIntermediateDirectories: true)
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyyMMdd-HHmmss"
                let url = folder.appendingPathComponent("手动调色记录-\(fmt.string(from: Date())).json")
                try json.write(to: url, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        }
    }
}
