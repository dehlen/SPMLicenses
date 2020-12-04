import Foundation

struct License: Codable {
    let packageName: String
    let licenseName: String
    let licenseText: String

    init(packageName: String, licenseName: String, licenseText: String) {
        self.packageName = packageName
        self.licenseName = licenseName
        self.licenseText = licenseText
    }
}
