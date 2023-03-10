import ShellClient
import Foundation

struct TestRunner {
  @Dependency(\.logger) var logger: Logger
  @Dependency(\.shellClient) var shell: ShellClient
  
  let platform: Platform
  let configuration: Configuration
  
  func run() throws {
    logger.info("\("Running for platform: \(platform)".bold)")
    
    try shell.foreground(
      .init(shell: .env, [
        "xcodebuild", "test",
        "-configuration", configuration,
        "-workspace", "ShellClient.xcworkspace",
        "-scheme", "ShellClient",
        "-destination", "platform=\(platform)"
      ])
    )
  }
}

enum Platform: String, CustomStringConvertible, CaseIterable {
  case macOS
  
  var description: String { rawValue }
}

enum Configuration: String, CustomStringConvertible, CaseIterable {
  case debug
  case release
  var description: String { rawValue }
}

func main() throws {
  for platform in Platform.allCases {
    for configuration in Configuration.allCases {
      try TestRunner(platform: platform, configuration: configuration).run()
    }
  }
}

try withDependencies {
  $0.logger.logLevel = .debug
} operation: {
  try main()
}

