import Dependencies
import Foundation
import ShellClient

func run() throws {
  @Dependency(\.logger) var logger
  @Dependency(\.shellClient) var shellClient
  
  enum GitStrings: String, CustomStringConvertible {
    case git
    case describe
    case tags = "--tags"
    case exactMatch = "--exact-match"
    case revParse = "rev-parse"
    case short = "--short"
    case HEAD = "HEAD"
    
    var description: String { rawValue }
  }
  
  // Silly example, you would generally do this in a background process.
  do {
    let arguments: [GitStrings] = [
      .git, .describe, .tags, .exactMatch
    ]
    try shellClient.foregroundShell(.init(arguments))
  } catch {
    logger.info("\("Warning: no tag found: Using commit.".red)")
    try shellClient.foregroundShell(
      .init(
        shell: .bash,
        GitStrings.git, .revParse, .short, .HEAD
      )
    )
  }
}

try withDependencies {
  $0.logger.logLevel = .debug
  $0.shellClient = .liveValue
} operation: {
  try run()
}

