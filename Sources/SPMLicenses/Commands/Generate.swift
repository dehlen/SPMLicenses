import Foundation
import ArgumentParser
import Combine

struct Generate: ParsableCommand {
    @Argument(help: "Path to your workspace, e.g. ~/code/MyProject/MyProject.xcworkspace")
    var workspacePath: String
    @Argument(help: "Path to the file to be created or replaced")
    var outputFile: String
    @Argument(help: "If providing client ID and client secret, the GitHub API call will have extended limits.")
    var gitClientID: String?
    @Argument(help: "If providing client ID and client secret, the GitHub API call will have extended limits.")
    var gitSecret: String?

    func run() throws {
        var cancelSet: Set<AnyCancellable> = []
        
        try exportLicenses()
            .sinkBlocking
            { (completion) in
                switch completion {
                case .finished:
                    ()
                case let .failure(error):
                    Self.exit(withError: error)
                }
            } receiveValue: { (licenses) in
                if !Writer(licenses, to: outputFile).write() {
                    Self.exit(withError: GenerateError.exportFailed)
                } else {
                    print("File was saved to: \(outputFile)")
                    Self.exit()
                }
            }.store(in: &cancelSet)

    }
    
    private func exportLicenses() throws -> AnyPublisher<[License], Never> {
        let packageParser = SPMPackageParser()
        let githubParser = GitHubParser(githubClientID: gitClientID, githubClientSecret: gitSecret)
        
        let packageResolvedFile = try packageParser.parse(from: workspacePath)
        let repositories = githubParser.extractPackageGitHubRepositories(from: packageResolvedFile)
        
        let licensesPublishers = repositories.map { repository in  githubParser.fetchGitHubLicenses(repository: repository.repository, githubClientID: gitClientID, githubClientSecret: gitSecret)
            .compactMap { response -> GitHubLicense? in
                do {
                    return try response.get()
                } catch {
                    print("Could not download license information for \(repository.package.package)")
                    return nil
                }
            }
            .flatMap { license in
                githubParser.downloadGitHubLicenseFile(url: license.downloadUrl)
                    .compactMap { response -> License? in
                        do {
                            let licenseText = try response.get()
                            return License(packageName: repository.package.package, licenseName: license.license.name, licenseText: licenseText)
                        } catch {
                            print("Could not download license information for \(repository.package.package)")
                            return nil
                        }
                    }
            }
            .eraseToAnyPublisher()
        }
        
        return Publishers.Sequence<[AnyPublisher<License, Never>], Never>(sequence: licensesPublishers)
            .flatMap { $0 }
            .collect()
            .eraseToAnyPublisher()
    }
}
