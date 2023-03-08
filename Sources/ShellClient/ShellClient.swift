import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct ShellClient {
  
  /// Run a shell command in the foreground.
  var foregroundShell: (LaunchPath, [String: String]?, [any CustomStringConvertible], String?) throws -> Void
  
  /// Run a shell command in the background, returning it's output as `Data`.
  var backgroundShellAsData: (LaunchPath, [String: String]?, [any CustomStringConvertible], String?) throws -> Data
  
  /// Create a new ``ShellClient`` instance.
  ///
  /// This is generally not interacted directly, instead access a shell client through the dependency values.
  /// ```swift
  ///   @Dependency(\.shellClient) var shellClient
  /// ```
  ///
  public init(
    foregroundShell: @escaping (LaunchPath, [String : String]?, [any CustomStringConvertible], String?) throws -> Void,
    backgroundShellAsData: @escaping (LaunchPath, [String : String]?, [any CustomStringConvertible], String?) throws -> Data
  ) {
    self.foregroundShell = foregroundShell
    self.backgroundShellAsData = backgroundShellAsData
  }
  
  /// Run a shell command in the foreground.
  ///
  /// - Parameters:
  ///   - shell: The shell launch path
  ///   - environmentOverrides: Override / set values in the process's environment.
  ///   - workingDirectory: Changes the directory to run the shell in.
  ///   - arguments: The shell command arguments to run.
  public func foregroundShell(
    shell: LaunchPath = .sh,
    environment environmentOverrides: [String: String]? = nil,
    workingDirectory: String? = nil,
    _ arguments: (any CustomStringConvertible)...
  ) throws {
    try self.foregroundShell(shell, environmentOverrides, arguments, workingDirectory)
  }
  
  /// Run a shell command in the background, returning it's output as `Data`.
  ///
  /// - Parameters:
  ///   - shell: The shell launch path
  ///   - environmentOverrides: Override / set values in the process's environment.
  ///   - workingDirectory: Changes the directory to run the shell in.
  ///   - arguments: The shell command arguments to run.
  @discardableResult
  public func backgroundShell<D: Decodable>(
    as decodable: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init(),
    shell: LaunchPath = .sh,
    environment environmentOverrides: [String: String]? = nil,
    workingDirectory: String? = nil,
    _ arguments: (any CustomStringConvertible)...
  ) throws -> D {
    
    let output = try self.backgroundShellAsData(
      shell,
      environmentOverrides,
      arguments,
      workingDirectory
    )
    
    return try jsonDecoder.decode(D.self, from: output)
  }
  
  /// Run a shell command in the background, returning it's output as a`String`.
  ///
  /// - Parameters:
  ///   - shell: The shell launch path
  ///   - environmentOverrides: Override / set values in the process's environment.
  ///   - workingDirectory: Changes the directory to run the shell in.
  ///   - trimmingCharactersIn: Returns the output string trimming the characters given.
  ///   - arguments: The shell command arguments to run.
  @discardableResult
  public func backgroundShell(
    shell: LaunchPath = .sh,
    environment environmentOverrides: [String: String]? = nil,
    workingDirectory: String? = nil,
    trimmingCharactersIn: CharacterSet? = nil,
    _ arguments: (any CustomStringConvertible)...
  ) throws -> String {
    let output = try self.backgroundShellAsData(
      shell, environmentOverrides, arguments, workingDirectory
    )
    let string = String(decoding: output, as: UTF8.self)
    guard let trimmingCharactersIn else { return string }
    return string.trimmingCharacters(in: trimmingCharactersIn)
  }
}

// MARK: - Overrides
extension ShellClient {
  
  /// Override's the background shell, returning the passed in data.
  ///
  /// This is useful for testing purposes.
  ///
  /// - Parameters:
  ///   - data: The data to return when one of the background shell methods are called.
  public mutating func overrideBackgroundShell(
    with data: Data
  ) {
    self.backgroundShellAsData = { _, _, _, _ in data }
  }
}

// MARK: - Test Dependency
extension ShellClient: TestDependencyKey {
  
  public static let testValue = Self.init(
    foregroundShell: unimplemented("\(Self.self).foregroundShell"),
    backgroundShellAsData: unimplemented("\(Self.self).backgroundShellData", placeholder: Data())
  )
}

extension DependencyValues {
  
  public var shellClient: ShellClient {
    get { self[ShellClient.self] }
    set { self[ShellClient.self] = newValue }
  }
}
