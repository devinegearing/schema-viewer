import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let schema = UTType(exportedAs: "ai.fastbreak.schema", conformingTo: .plainText)
}

struct SchemaDocument: FileDocument {
    var source: String
    var fileURL: URL?

    static var readableContentTypes: [UTType] { [.schema] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        source = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(source.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
