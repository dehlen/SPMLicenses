import Foundation

struct ResolvedPackageContent: Decodable {
    let object: ResolvedPackageObject
    let version: Int
}

struct ResolvedPackageObject: Decodable {
    let pins: [ResolvedPackage]
}

struct ResolvedPackage: Decodable {
    let package: String
    let repositoryURL: URL
    let state: ResolvedPackageState
}

struct ResolvedPackageState: Decodable {
    let branch: String?
    let revision: String?
    let version: String?
}
