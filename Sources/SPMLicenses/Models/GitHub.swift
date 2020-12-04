import Foundation

typealias GitHubRepository = (owner: String, name: String)

struct GitHubLicense: Decodable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let url: URL?
    let htmlUrl: URL?
    let gitUrl: URL?
    let downloadUrl: URL
    let type: String?
    let content: String?
    let encoding: String?
    let license: LicenseDetails

    var licenseName: String {
        license.name
    }

    struct LicenseDetails: Decodable {
        let key: String
        let name: String
        let spdx_id: String?
        let url: URL?
        let node_id: String?
    }
}
