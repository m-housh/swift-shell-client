import  Dependencies
import Foundation
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
fileprivate func runCommand(command: ShellCommand, context: RunContext) throws -> Data {
  @Dependency(\.logger) var logger: Logger
  
  let isForeground = context.isForeground
  let style = isForeground ? "foreground" : "background"
  
  logger.debug("\("Running in \(style.underline) shell.".green.bold)")
  
  let task = Process.configure(command: command, context: context)
  return try task.runReturningData(isForeground: isForeground)
}

fileprivate func runCommand(command: ShellCommand, context: RunContext) async throws -> Data {
  @Dependency(\.logger) var logger: Logger
  
  let isForeground = context.isForeground
  
  let style = isForeground ? "foreground" : "background"
  logger.debug("\("Running in \(style.underline) shell.".green.bold)")
  
  let task = Process.configure(command: command, context: context)
  return try await task.runReturningData(isForeground: isForeground)
}

fileprivate struct ShellError: Error {
  var terminationStatus: Int32
}

fileprivate extension Process {
  
  static func configure(command: ShellCommand, context: RunContext) -> Process {
    @Dependency(\.logger) var logger: Logger
    
    let process = Process()
    var arguments = flattenArguments(command.arguments).map(\.description)
    
    if command.launchPath.useDashC {
      // condense to a single argument to be passed to -c commands.
      arguments = [
        "-c",
        arguments.joined(separator: " ")
      ]
    }
    
    let message = """
      \("$".magenta) \(command.launchPath.description.blue) \(arguments.joined( separator: " "))
      """
    
    logger.info("\(message)")
    
    var processEnvironment = ProcessInfo.processInfo.environment
    if let environment = command.environment {
      processEnvironment.merge(environment, uniquingKeysWith: { $1 })
    }
    
    process.executableURL = command.launchPath.url
    process.arguments = arguments
    process.environment = processEnvironment
    if let workingDirectory = command.workingDirectory {
      process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
    }
   
    return process
  }
}

// Flatten any arrays into single values.
fileprivate func flattenArguments(
  _ arguments: [any CustomStringConvertible]
) -> [any CustomStringConvertible] {
  
  var output: [any CustomStringConvertible] = []
  
  for argument in arguments {
    if let array = argument as? [any CustomStringConvertible] {
      output += flattenArguments(array)
    } else {
      output.append(argument)
    }
  }
  
  return output
  
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
    var output: Pipe?
    if !isForeground {
      output = Pipe()
      self.standardOutput = output!
    
      let error = Pipe()
      self.standardError = error
    }
    
    try self.run()
    self.waitUntilExit()
    
    guard self.terminationStatus == 0 else {
      throw ShellError(terminationStatus: self.terminationStatus)
    }
    
    return output?.data() ?? Data()
  }
  
  func runReturningData(isForeground: Bool) async throws -> Data {
    
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
      self.terminationHandler = { process in
        var output: Pipe?
        if !isForeground {
          output = Pipe()
          process.standardOutput = output!
          
          let error = Pipe()
          process.standardError = error
        }
        
        if process.terminationStatus != 0 {
          continuation.resume(throwing: ShellError(terminationStatus: process.terminationStatus))
        } else {
          continuation.resume(returning: output?.data() ?? Data())
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
