import Dependencies
import Foundation
import Logging
import ShellClient

// This is silly, just show casing custom string convertible works.
enum GitCommand {
  case describe([DescribeArgs] = DescribeArgs.allCases)
  case revParse([RevParseArgs] = RevParseArgs.allCases)
  
  enum DescribeArgs: String, CustomStringConvertible, CaseIterable {
    case exactMatch = "--exact-match"
    case tags = "--tags"
  }
  
  enum RevParseArgs: String, CustomStringConvertible, CaseIterable {
    case head = "HEAD"
  }
  
  var arguments: [any CustomStringConvertible] {
    switch self {
    case .describe(let args):
      return ["describe"] + args
    case .revParse(let args):
      return ["rev-parse"] + args
    }
  }
}

extension RawRepresentable where RawValue == String, Self: CustomStringConvertible {
  var description: String { rawValue }
}

extension ShellCommand {
  static func git(shell: Shell? = nil, _ command: GitCommand) -> Self {
    .init(
      shell: shell ?? Self.defaultShell,
      arguments: ["git"] + command.arguments
    )
  }
}

// A small example tool that uses the shell-client to show the current
// git tag or the git sha if a tag is not found / set.
func run() throws {
  @Dependency(\.logger) var logger
  @Dependency(\.shellClient) var shell
  
  // Silly example, you would generally do this in a background process.
  do {
    try shell.foreground(.git(.describe()))
  } catch {
    logger.info("\("Warning: no tag found: Using commit.".red)")
    try shell.foreground(.git(shell: .env(.bash), .revParse()))
  }
}

var logger = basicLogger(.showing(label: "version-example".green))

#if DEBUG
  logger.logLevel = .debug
#else
  logger.logLevel = .info
#endif

try withDependencies {
  $0.logger = logger
  $0.shellClient = .liveValue
} operation: {
  try run()
}
