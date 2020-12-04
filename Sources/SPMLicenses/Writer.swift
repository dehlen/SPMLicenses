import Foundation

class Writer<T: Codable> {
    let items: T
    let outputFile: String
    let fileManager: FileManager
    let encoder: JSONEncoder

    init(_ items: T, to outputFile: String, fileManager: FileManager = .default, encoder: JSONEncoder = JSONEncoder()) {
        self.items = items
        self.outputFile = outputFile
        self.fileManager = fileManager
        self.encoder = encoder
    }

    func write() -> Bool {
        do {
            let data = try encoder.encode(items)
            let result = fileManager.createFile(atPath: outputFile, contents: data)
            if !result {
                print("Could not save licenses file")
            }
            return result
        } catch {
            print("Could not save licenses file")
            return false
        }
    }
}
