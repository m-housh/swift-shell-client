import Dependencies
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging
import Rainbow

extension ShellClient: DependencyKey {
  
  public static var liveValue: ShellClient {
    .init(
      foregroundShell: { shell, environment, arguments, workingDirectory in
        try runCommand(
          shell: shell,
          environment: environment,
          arguments: arguments.map(\.description),
          workingDirectory: workingDirectory,
          isForeground: true
        )
      },
      backgroundShellAsData: { shell, environment, arguments, workingDirectory in
        try runCommand(
          shell: shell,
          environment: environment,
          arguments: arguments.map(\.description),
          workingDirectory: workingDirectory,
          isForeground: false
        )
      }
    )
  }
}

extension AsyncShellClient: DependencyKey {
  
  public static var liveValue: AsyncShellClient {
    .init(
      foregroundShell: { shell, environment, arguments, workingDirectory in
        try await runCommand(
          shell: shell,
          environment: environment,
          arguments: arguments.map(\.description),
          workingDirectory: workingDirectory,
          isForeground: true
        )
      },
      backgroundShellAsData: { shell, environment, arguments, workingDirectory in
        try await runCommand(
          shell: shell,
          environment: environment,
          arguments: arguments.map(\.description),
          workingDirectory: workingDirectory,
          isForeground: false
        )
      }
    )
  }
}

// MARK: - Helpers
@discardableResult
fileprivate func runCommand(
  shell: LaunchPath,
  environment: [String: String]?,
  arguments: [String],
  workingDirectory: String?,
  isForeground: Bool
) throws -> Data {
  @Dependency(\.logger) var logger: Logger
  
  let style = isForeground ? "foreground" : "background"
  
  logger.debug("\("Running in \(style.underline) shell.".green.bold)")
  logger.info("\("$".magenta) \(arguments.joined(separator: " "))")
  
  let arguments = shell.useDashC ? ["-c"] + arguments : arguments
  var processEnvironment = ProcessInfo.processInfo.environment
  if let environment {
    processEnvironment.merge(environment, uniquingKeysWith: { $1 })
  }

  let task = Process()
  task.executableURL = shell.url
  task.arguments = arguments
  task.environment = processEnvironment
  if let workingDirectory {
    task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
  }
  return try task.runReturningData(isForeground: isForeground)
}

@discardableResult
fileprivate func runCommand(
  shell: LaunchPath,
  environment: [String: String]?,
  arguments: [String],
  workingDirectory: String?,
  isForeground: Bool
) async throws -> Data {
  @Dependency(\.logger) var logger: Logger
  
  let style = isForeground ? "foreground" : "background"
  
  logger.debug("\("Running in \(style.underline) shell.".green.bold)")
  logger.info("\("$".magenta) \(arguments.joined(separator: " "))")
  
  let arguments = shell.useDashC ? ["-c"] + arguments : arguments
  var processEnvironment = ProcessInfo.processInfo.environment
  if let environment {
    processEnvironment.merge(environment, uniquingKeysWith: { $1 })
  }

  let task = Process()
  task.executableURL = shell.url
  task.arguments = arguments
  task.environment = processEnvironment
  if let workingDirectory {
    task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
  }
  return try await task.runReturningData(isForeground: isForeground)
}

fileprivate struct ShellError: Error {
  var terminationStatus: Int32
}

fileprivate extension Pipe {
  
  func data() -> Data {
    if #available(macOS 10.15.4, *) {
      guard let data = try? self.fileHandleForReading.readToEnd() else {
        return Data()
      }
      return data
    } else {
      // Fallback on earlier versions
      return self.fileHandleForReading.readDataToEndOfFile()
    }
  }
}

extension Process {
  
  func runReturningData(isForeground: Bool) throws -> Data {
    let output = Pipe()
    self.standardOutput = output
    
    if !isForeground {
      let error = Pipe()
      self.standardError = error
    }
    
    try self.run()
    self.waitUntilExit()
    
    guard self.terminationStatus == 0 else {
      throw ShellError(terminationStatus: self.terminationStatus)
    }
    
    return output.data()
  }
  
  func runReturningData(isForeground: Bool) async throws -> Data {
    let output = Pipe()
    self.standardOutput = output
    
    if !isForeground {
      let error = Pipe()
      self.standardError = error
    }
    
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
      self.terminationHandler = { process in
        if process.terminationStatus != 0 {
          continuation.resume(throwing: ShellError(terminationStatus: process.terminationStatus))
        } else {
          continuation.resume(returning: output.data())
        }
      }
      
      do {
        try self.run()
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}
