import SwiftUI
import WebKit
import PhotosUI

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
        configuration.userContentController.add(context.coordinator, name: "quSeQiListBackups")
        configuration.userContentController.add(context.coordinator, name: "quSeQiRestoreBackup")
        configuration.userContentController.add(context.coordinator, name: "quSeQiOpenURL")
        configuration.userContentController.add(context.coordinator, name: "quSeQiPickImage")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.bounces = false
        context.coordinator.webView = webView

        if let fileURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKScriptMessageHandler, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "quSeQiPickImage" {
                let source = (message.body as? String) ?? "library"
                DispatchQueue.main.async { [weak self] in
                    self?.presentNativeImagePicker(source: source)
                }
                return
            }
            if message.name == "quSeQiOpenURL" {
                if let urlStr = message.body as? String, let url = URL(string: urlStr),
                   ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                return
            }
            if message.name == "quSeQiListBackups" {
                let files = listBackupFiles()
                if let data = try? JSONSerialization.data(withJSONObject: files),
                   let jsonStr = String(data: data, encoding: .utf8) {
                    let js = "window.quSeQiBackupListResult && window.quSeQiBackupListResult('\(jsonStr.replacingOccurrences(of: "'", with: "\\'"))')"
                    DispatchQueue.main.async { [weak self] in
                        self?.webView?.evaluateJavaScript(js, completionHandler: nil)
                    }
                }
                return
            }
            if message.name == "quSeQiRestoreBackup" {
                guard let filename = message.body as? String else { return }
                let content = readBackupFile(filename)
                let escaped = (content ?? "").replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "'", with: "\\'")
                    .replacingOccurrences(of: "\n", with: "\\n")
                let js = "window.quSeQiRestoreResult && window.quSeQiRestoreResult('\(escaped)')"
                DispatchQueue.main.async { [weak self] in
                    self?.webView?.evaluateJavaScript(js, completionHandler: nil)
                }
                return
            }
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

        private func backupFolder() -> URL? {
            let fm = FileManager.default
            guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            return docs.appendingPathComponent("涂料配色")
        }

        private func listBackupFiles() -> [[String: String]] {
            guard let folder = backupFolder() else { return [] }
            let fm = FileManager.default
            guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey]) else { return [] }
            let jsons = files.filter { $0.pathExtension == "json" }
            let sorted = jsons.sorted { (a, b) -> Bool in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return da > db
            }
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd HH:mm"
            return sorted.map { url in
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return ["name": url.lastPathComponent, "time": fmt.string(from: date), "size": "\(size / 1024)KB"]
            }
        }

        private func readBackupFile(_ filename: String) -> String? {
            guard let folder = backupFolder() else { return nil }
            // 防止路径穿越
            let safeName = URL(fileURLWithPath: filename).lastPathComponent
            let url = folder.appendingPathComponent(safeName)
            return try? String(contentsOf: url, encoding: .utf8)
        }

        // MARK: - 原生图片选择（拍照 / 相册）
        private func topViewController() -> UIViewController? {
            var responder: UIResponder? = webView
            while responder != nil {
                if let vc = responder as? UIViewController { return vc }
                responder = responder?.next
            }
            return webView?.window?.rootViewController
        }

        private func presentNativeImagePicker(source: String) {
            guard let vc = topViewController() else { return }
            if source == "camera" {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                vc.present(picker, animated: true)
            } else {
                var config = PHPickerConfiguration()
                config.filter = .images
                config.selectionLimit = 1
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                vc.present(picker, animated: true)
            }
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                sendImageToWeb(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                if let image = object as? UIImage {
                    self?.sendImageToWeb(image)
                }
            }
        }

        private func sendImageToWeb(_ image: UIImage) {
            let maxEdge: CGFloat = 1920
            var finalImage = image
            let longest = max(image.size.width, image.size.height)
            if longest > maxEdge {
                let scale = maxEdge / longest
                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                if let resized = UIGraphicsGetImageFromCurrentImageContext() { finalImage = resized }
                UIGraphicsEndImageContext()
            }
            guard let data = finalImage.jpegData(compressionQuality: 0.85) else { return }
            let b64 = data.base64EncodedString()
            let js = "window.quSeQiImageResult && window.quSeQiImageResult('data:image/jpeg;base64,\(b64)')"
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
