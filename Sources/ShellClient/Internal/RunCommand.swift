import Dependencies
import Foundation
import Logging
import Rainbow

extension ShellCommand {

  @discardableResult
  func run(in context: RunContext) throws -> Data {
    try runCommand(command: self, context: context)
  }

  @discardableResult
  func run(in context: RunContext) async throws -> Data {
    try await runCommand(command: self, context: context)
  }
}

enum RunContext {
  case foreground
  case background

  fileprivate var isForeground: Bool {
    switch self {
    case .foreground:
      return true
    case .background:
      return false
    }
  }
}

// MARK: - Private

private func runCommand(command: ShellCommand, context: RunContext) throws -> Data {
  @Dependency(\.logger) var logger: Logger

  let isForeground = context.isForeground
  let style = isForeground ? "foreground" : "background"

  logger.debug("\("Running in \(style.underline.bold) shell.".cyan)")

  let task = Process.configure(command: command, context: context)
  return try task.runReturningData(isForeground: isForeground)
}

private func runCommand(command: ShellCommand, context: RunContext) async throws -> Data {
  @Dependency(\.logger) var logger: Logger

  let isForeground = context.isForeground

  let style = isForeground ? "foreground" : "background"
  logger.debug("\("Running in \(style.underline.bold) shell.".cyan)")

  let task = Process.configure(command: command, context: context)
  return try await task.runReturningData(isForeground: isForeground)
}

private struct ShellError: Error {
  var terminationStatus: Int32
}

private extension Process {

  static func configure(command: ShellCommand, context: RunContext) -> Process {
    @Dependency(\.logger) var logger: Logger

    let process = Process()
    var arguments = flattenArguments(command.arguments).map(\.description)

    if command.shell.useDashC && arguments.count > 0 {
      // condense to a single argument to be passed to -c commands.
      arguments = [
        "-c",
        arguments.joined(separator: " ")
      ]
    }

    var shellDescription = command.shell.description
    if case let .env(optionalEnv) = command.shell,
       let env = optionalEnv
    {
      shellDescription += " \(env.name)"
    }

    let message = """
    \("$".magenta) \(shellDescription.blue) \(arguments.joined(separator: " "))
    """

    logger.debug("\(message)")

    var processEnvironment = ProcessInfo.processInfo.environment
    if let environment = command.environment {
      processEnvironment.merge(environment, uniquingKeysWith: { $1 })
    }

    process.executableURL = command.shell.url
    process.arguments = arguments.count > 0 ? arguments : nil
    process.environment = processEnvironment
    if let workingDirectoryUrl = command.workingDirectoryUrl {
      process.currentDirectoryURL = workingDirectoryUrl
    }

    return process
  }
}

// Flatten any nested arrays into single elements.
private func flattenArguments(
  _ arguments: [any CustomStringConvertible]
) -> [any CustomStringConvertible] {
  var output: [any CustomStringConvertible] = []

  for argument in arguments {
    if let array = argument as? [any CustomStringConvertible] {
      // recursively call ourself, to flatten arrays into single elements.
      output += flattenArguments(array)
    } else {
      // we are a single element so append it to the output.
      output.append(argument)
    }
  }

  return output
}

private extension Pipe {

  func data() -> Data {
    if #available(macOS 10.15.4, *) {
      guard let data = try? self.fileHandleForReading.readToEnd() else {
        return Data()
      }
      return data
    } else {
      // Fallback on earlier versions
      return fileHandleForReading.readDataToEndOfFile()
    }
  }
}

private extension Process {

  func runReturningData(isForeground: Bool) throws -> Data {
    var output: Pipe?
    if !isForeground {
      output = Pipe()
      standardOutput = output!

      let error = Pipe()
      standardError = error
    }

    try run()
    waitUntilExit()

    guard terminationStatus == 0 else {
      throw ShellError(terminationStatus: terminationStatus)
    }

    return output?.data() ?? Data()
  }

  func runReturningResult(isForeground: Bool) -> Result<Data, Error> {
    .init(catching: {
      try self.runReturningData(isForeground: isForeground)
    })
  }

  func runReturningData(isForeground: Bool) async throws -> Data {
    return try await withCheckedThrowingContinuation { continuation in
      let result = self.runReturningResult(isForeground: isForeground)
      continuation.resume(with: result)
    }
  }
}
