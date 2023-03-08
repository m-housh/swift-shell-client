import Dependencies
import Foundation
import ShellClient

let shellClient = withDependencies {
  $0.logger.logLevel = .debug
} operation: {
  return ShellClient.liveValue
}

do {
  try shellClient.foregroundShell(
    "git", "describe", "--tags", "--exact-match"
  )
} catch {
  try shellClient.foregroundShell(
    "git", "rev-parse", "--short", "HEAD"
  )
}
