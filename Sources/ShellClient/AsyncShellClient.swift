import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct AsyncShellClient {
  
  /// Run a shell command in the foreground.
  var foregroundShell: (ShellCommand) async throws -> Void
  
  /// Run a shell command in the background, returning it's output as `Data`.
  var backgroundShell: (ShellCommand) async throws -> Data
  
  /// Create a new ``ShellClient`` instance.
  ///
  /// This is generally not interacted directly, instead access a shell client through the dependency values.
  /// ```swift
  ///   @Dependency(\.shellClient) var shellClient
  /// ```
  ///
  public init(
    foregroundShell: @escaping (ShellCommand) async throws -> Void,
    backgroundShell: @escaping (ShellCommand) async throws -> Data
  ) {
    self.foregroundShell = foregroundShell
    self.backgroundShell = backgroundShell
  }
  
    
  /// Run a shell command in the foreground.
  ///
  /// - Parameters:
  ///   - command: The shell command to run.
  public func foregroundShell(_ command: ShellCommand) async throws {
    try await foregroundShell(command)
  }
   
  /// Run a shell command in the background, decoding it's output.
  ///
  /// - Parameters:
  ///   - decodable: The type to decode.
  ///   - jsonDecoder: The json decoder to use for decoding.
  ///   - command: The shell command to run.
  @discardableResult
  public func backgroundShell<D: Decodable>(
    command: ShellCommand,
    as decodable: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init()
  ) async throws -> D {
    let output = try await self.backgroundShell(command)
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
    _ command: ShellCommand,
    trimmingCharactersIn: CharacterSet? = nil
  ) async throws -> String {
    let output = try await self.backgroundShell(command)
    let string = String(decoding: output, as: UTF8.self)
    guard let trimmingCharactersIn else { return string }
    return string.trimmingCharacters(in: trimmingCharactersIn)
  }
}

// MARK: - Overrides
extension AsyncShellClient {
  
  /// Override's the background shell, returning the passed in data.
  ///
  /// This is useful for testing purposes.
  ///
  /// - Parameters:
  ///   - data: The data to return when one of the background shell methods are called.
  public mutating func overrideBackgroundShell(
    with data: Data
  ) {
    self.backgroundShell = { _ in data }
  }
}

// MARK: - Dependency
extension AsyncShellClient: DependencyKey {
  
  public static let testValue = Self.init(
    foregroundShell: unimplemented("\(Self.self).foregroundShell"),
    backgroundShell: unimplemented("\(Self.self).backgroundShellData", placeholder: Data())
  )
  
  public static var liveValue: AsyncShellClient {
    .init(
      foregroundShell: { try $0.run(in: .foreground) },
      backgroundShell: { try $0.run(in: .background) }
    )
  }
}

extension DependencyValues {
  
  public var asyncShellClient: AsyncShellClient {
    get { self[AsyncShellClient.self] }
    set { self[AsyncShellClient.self] = newValue }
  }
}
