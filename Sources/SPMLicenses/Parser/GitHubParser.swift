import Foundation
import Combine

class GitHubParser {
    typealias PackageRepository = (package: ResolvedPackage, repository: GitHubRepository)

    private let githubClientID: String?
    private let githubClientSecret: String?

    init(githubClientID: String? = nil, githubClientSecret: String? = nil) {
        self.githubClientID = githubClientID
        self.githubClientSecret = githubClientSecret
    }
    
    func extractPackageGitHubRepositories(from packageContent: ResolvedPackageContent) -> [PackageRepository] {
        packageContent.object.pins.compactMap { package in
            do {
                let repository = try githubRepository(from: package.repositoryURL)
                return PackageRepository(package: package, repository: repository)
            } catch {
                print("Ignoring project \(package.package) because we don't know how to fetch the license from it")
                return nil
            }
        }
    }
    
    func githubRepository(from url: URL) throws -> GitHubRepository {
        let gitDomain = "github.com"
        let gitSuffix = ".git"

        guard let host = url.host,
            host.contains(gitDomain),
            url.pathComponents.count >= 2
        else {
            throw GitHubError.unknownRepository
        }
        
        let owner = url.pathComponents[url.pathComponents.count - 2]
        let name = url.pathComponents[url.pathComponents.count - 1]
        let nameWithoutSuffix = name.hasSuffix(gitSuffix) ? String(name.dropLast(gitSuffix.count)) : name
        
        return GitHubRepository(
            owner: owner,
            name: nameWithoutSuffix
        )
    }
    
    func fetchGitHubLicenses(
        session: URLSession = .shared,
        repository: GitHubRepository,
        githubClientID: String?,
        githubClientSecret: String?
    ) -> AnyPublisher<Result<GitHubLicense, GitHubError>, Never> {
        guard let url = URL(string: "https://api.github.com/repos/\(repository.owner)/\(repository.name)/license") else {
            return Just(.failure(.invalidLicenseMetadataURL))
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        if
            let clientId = githubClientID,
            let clientSecret = githubClientSecret,
            let authenticationHeader = "\(clientId):\(clientSecret)".data(using: .utf8) {
            let basicAuthenticationHeader = "Basic \(authenticationHeader.base64EncodedString())"
            request.addValue(basicAuthenticationHeader, forHTTPHeaderField: "Authorization")
        }

        print("Fetching from \(url)")

        return session.dataTaskPublisher(for: request)
            .retry(2)
            .mapError { error in GitHubError.requestError(error) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode else {
                    throw GitHubError.invalidResponse(response)
                }
                return data
            }.decode(type: GitHubLicense.self, decoder: JSONDecoder())
            .mapError { error in GitHubError.parsingError(error) }
            .map {
                return .success($0)
            }
            .catch { error in
                return Just(.failure(error))
            }
            .eraseToAnyPublisher()
    }

    func downloadGitHubLicenseFile(session: URLSession = .shared, url: URL) -> AnyPublisher<Result<String, GitHubError>, Never> {
        session.dataTaskPublisher(for: url)
            .retry(2)
            .map { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode else {
                    return .failure(.invalidResponse(response))
                }
                
                guard let licenseText = String(data: data, encoding: .utf8) else {
                    return .failure(.conversionError)
                }
                
                return .success(licenseText)
            }
            .catch { error in Just(.failure(GitHubError.requestError(error))) }
            .eraseToAnyPublisher()
    }
}
