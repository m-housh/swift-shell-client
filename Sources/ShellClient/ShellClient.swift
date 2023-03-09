import Dependencies
import Foundation
import XCTestDynamicOverlay

/// Run shell commands from your swift code.
///
///
public struct ShellClient {
  
  /// Run a shell command in the foreground.
  ///
  /// This is generally not interacted with directly, instead use ``ShellClient/ShellClient/foreground(_:)``
  public private(set) var foregroundShell: (ShellCommand) throws -> Void
  
  /// Run a shell command in the background, returning it's output as `Data`.
  ///
  /// This is generally not interacted with directly, instead use one of the background methods, such as
  /// ``ShellClient/ShellClient/background(command:as:decodedBy:)``
  public private(set) var backgroundShell: (ShellCommand) throws -> Data
  
  /// Create a new ``ShellClient`` instance.
  ///
  /// This is generally not interacted directly, instead access a shell client through the dependency values.
  /// ```swift
  ///   @Dependency(\.shellClient) var shellClient
  /// ```
  ///
  public init(
    foregroundShell: @escaping (ShellCommand) throws -> Void,
    backgroundShell: @escaping (ShellCommand) throws -> Data
  ) {
    self.foregroundShell = foregroundShell
    self.backgroundShell = backgroundShell
  }
    
  /// Run a shell command in the foreground.
  ///
  /// - Parameters:
  ///   - command: The shell command to run.
  public func foreground(_ command: ShellCommand) throws {
    try self.foregroundShell(command)
  }
 
  /// Run a shell command in the background, decoding it's output.
  ///
  /// - Parameters:
  ///   - decodable: The type to decode from the output.
  ///   - jsonDecoder: The json decoder to use.
  ///   - command: The shell command to run.
  @discardableResult
  public func background<D: Decodable>(
    command: ShellCommand,
    as decodable: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init()
  ) throws -> D {
    let output = try self.backgroundShell(command)
    return try jsonDecoder.decode(D.self, from: output)
  }
  
  /// Run a shell command in the background, returning it's output as a`String`.
  ///
  /// - Parameters:
  ///   - command: The shell command to run.
  ///   - trimmingCharactersIn: Returns the output string trimming the characters given.
  @discardableResult
  public func background(
    _ command: ShellCommand,
    trimmingCharactersIn: CharacterSet? = nil
  ) throws -> String {
    let output = try self.backgroundShell(command)
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
    self.backgroundShell = { _ in data }
  }
  
  /// Override's the foreground shell implementation.
  ///
  /// This is useful for testing purposes.
  ///
  /// - Parameters:
  ///   - closure: The closure to run when a foreground shell is called.
  public mutating func overrideForegroundShell(
    with closure: @escaping (ShellCommand) throws -> Void
  ) {
    self.foregroundShell = closure
  }
}

// MARK: - Dependency
extension ShellClient: DependencyKey {
  
  /// The ``ShellClient/ShellClient`` that is used in a testing context, which is unimplemented,
  /// meaning you will need to override the methods that get used, using one of the override methods, such as
  /// ``ShellClient/ShellClient/overrideBackgroundShell(with:)`` or
  /// ``ShellClient/ShellClient/overrideForegroundShell(with:)``.
  ///
  public static let testValue = Self.init(
    foregroundShell: unimplemented("\(Self.self).foregroundShell"),
    backgroundShell: unimplemented("\(Self.self).backgroundShellData", placeholder: Data())
  )
  
  /// The ``ShellClient/ShellClient`` that is used in a live context.
  ///
  public static var liveValue: ShellClient {
    .init(
      foregroundShell: { try $0.run(in: .foreground) },
      backgroundShell: { try $0.run(in: .background) }
    )
  }
}

extension DependencyValues {
  
  /// Access a ``ShellClient/ShellClient`` as a dependency.
  public var shellClient: ShellClient {
    get { self[ShellClient.self] }
    set { self[ShellClient.self] = newValue }
  }
}
