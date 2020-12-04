import Foundation
import Combine

class SPMPackageParser {
    func parse(from workspacePath: String) throws -> ResolvedPackageContent {
        let resolvedFileURL = try packageResolvedFile(from: workspacePath)
        return try readSwiftPackageResolvedJson(url: resolvedFileURL)
    }
    
    private func packageResolvedFile(from workspacePath: String) throws -> URL {
        let (exists, isDirectory) = pathExists(workspacePath)
        guard exists else { throw SPMError.workspacePathDoesNotExist }
        guard isDirectory else { throw SPMError.workspacePathIsNotAFolder }

        let workspaceURL = URL(fileURLWithPath: workspacePath, isDirectory: true)
        let packageResolved = workspaceURL
            .appendingPathComponent("xcshareddata", isDirectory: true)
            .appendingPathComponent("swiftpm", isDirectory: true)
            .appendingPathComponent("Package.resolved", isDirectory: false)

        guard pathExists(packageResolved.path) == (exists: true, isDirectory: false) else {
            throw SPMError.swiftPackageNotPresent
        }

        return packageResolved
    }

    private func readSwiftPackageResolvedJson(url: URL) throws -> ResolvedPackageContent {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ResolvedPackageContent.self, from: data)
        } catch {
            throw SPMError.switPackageParsingError(error)
        }
    }
    
    private typealias PathExists = (exists: Bool, isFolder: Bool)

    private func pathExists(_ path: String) -> PathExists {
        var isFolder: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isFolder)
        return (exists: exists, isFolder: isFolder.boolValue)
    }
}
