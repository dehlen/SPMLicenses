import ArgumentParser

struct SPMLicenses: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to generate licenses from spm dependencies",
        subcommands: [Generate.self])

    init() { }
}
