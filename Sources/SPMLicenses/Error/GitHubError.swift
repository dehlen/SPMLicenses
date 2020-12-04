import Foundation

enum GitHubError: Error {
    case unknownRepository
    case invalidLicenseMetadataURL
    case requestError(Error)
    case invalidResponse(URLResponse)
    case parsingError(Error)
}
