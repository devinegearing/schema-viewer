import Foundation

enum SchemaPageBuilder {
    static func buildPage(source: String) -> String {
        let elkJS = loadResource("elk.bundled", withExtension: "js") ?? ""
        let template = loadResource("schema-template", withExtension: "html") ?? ""

        let escaped = jsonEscape(source)
        return template
            .replacingOccurrences(of: "{{SCHEMA_SOURCE}}", with: escaped)
            .replacingOccurrences(of: "{{ELK_JS}}", with: elkJS)
    }

    private static func loadResource(_ name: String, withExtension ext: String) -> String? {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func jsonEscape(_ string: String) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: string,
            options: [.fragmentsAllowed]
        ),
            let json = String(data: data, encoding: .utf8)
        else {
            let escaped = string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            return "\"\(escaped)\""
        }
        return json
    }
}
