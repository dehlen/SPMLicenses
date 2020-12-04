enum SPMError: Error {
    case workspacePathDoesNotExist
    case workspacePathIsNotAFolder
    case swiftPackageNotPresent
    case switPackageParsingError(Error)
}
