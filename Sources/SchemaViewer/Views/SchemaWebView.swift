import SwiftUI
import WebKit

struct SchemaWebView: NSViewRepresentable {
    let source: String
    let fileURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(fileURL: fileURL)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let contentController = config.userContentController
        contentController.add(context.coordinator, name: "save")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        let html = SchemaPageBuilder.buildPage(source: source)
        webView.loadHTMLString(html, baseURL: nil)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let fileURL: URL?

        init(fileURL: URL?) {
            self.fileURL = fileURL
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "save",
                  let newSource = message.body as? String,
                  let url = fileURL
            else { return }

            do {
                try newSource.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                NSLog("SchemaViewer: failed to save: \(error)")
            }
        }
    }
}
