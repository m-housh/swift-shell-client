import Dependencies
import DependenciesMacros
import Foundation
import XCTestDynamicOverlay

public extension DependencyValues {

  /// Access a ``ShellClient/AsyncShellClient`` as a dependency.
  var asyncShellClient: AsyncShellClient {
    get { self[AsyncShellClient.self] }
    set { self[AsyncShellClient.self] = newValue }
  }
}

/// Run shell commands from your swift code.
///
///
@DependencyClient
public struct AsyncShellClient: Sendable {

  /// Run a shell command in the foreground.  ///
  ///
  /// This is generally not interacted with directly, instead use ``ShellClient/AsyncShellClient/foreground(_:)``
  var foregroundShell: @Sendable (ShellCommand) async throws -> Void

  /// Run a shell command in the background, returning it's output as `Data`.
  ///
  /// This is generally not interacted with directly, instead use one of the background methods, such as
  /// ``ShellClient/AsyncShellClient/background(command:as:decodedBy:)``
  var backgroundShell: @Sendable (ShellCommand) async throws -> Data

  /// Run a shell command in the foreground.
  ///
  /// - Parameters:
  ///   - command: The shell command to run.
  public func foreground(_ command: ShellCommand) async throws {
    try await foregroundShell(command)
  }

  /// Run a shell command in the background, decoding it's output.
  ///
  /// - Parameters:
  ///   - command: The shell command to run.
  ///   - decodable: The type to decode from the output.
  ///   - jsonDecoder: The json decoder to use for decoding.
  @discardableResult
  public func background<D: Decodable>(
    command: ShellCommand,
    as decodable: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init()
  ) async throws -> D {
    let output = try await backgroundShell(command)
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
  ) async throws -> String {
    let output = try await backgroundShell(command)
    let string = String(bytes: output, encoding: .utf8) ?? ""
    guard let trimmingCharactersIn else { return string }
    return string.trimmingCharacters(in: trimmingCharactersIn)
  }
}

// MARK: - Overrides

public extension AsyncShellClient {

  /// Override's the background shell, returning the passed in data.
  ///
  /// This is useful for testing purposes.
  ///
  /// - Parameters:
  ///   - data: The data to return when one of the background shell methods are called.
  mutating func overrideBackgroundShell(
    with data: Data
  ) {
    backgroundShell = { _ in data }
  }

  /// Override's the foreground shell implementation.
  ///
  /// This is useful for testing purposes.
  ///
  /// - Parameters:
  ///   - closure: The closure to run when a foreground shell is called.
  mutating func overrideForegroundShell(
    with closure: @Sendable @escaping (ShellCommand) async throws -> Void
  ) {
    foregroundShell = closure
  }
}

// MARK: - Dependency

extension AsyncShellClient: DependencyKey {

  /// The ``ShellClient/AsyncShellClient`` that is used in a testing context, which is unimplemented,
  /// meaning you will need to override the methods that get used, using one of the override methods, such as
  /// ``ShellClient/AsyncShellClient/overrideBackgroundShell(with:)`` or
  /// ``ShellClient/AsyncShellClient/overrideForegroundShell(with:)``.
  ///
  public static let testValue = Self()

  /// The ``ShellClient/AsyncShellClient`` that is used in a live context.
  ///
  public static var liveValue: AsyncShellClient {
    .init(
      foregroundShell: { try await $0.run(in: .foreground) },
      backgroundShell: { try await $0.run(in: .background) }
    )
  }

  /// An async shell client that can capture the command it's supposed to run.
  ///
  /// This is useful for testing and ensuring the arguments, etc. are set appropriately.
  ///
  /// - Parameters:
  ///   - captured: The capture command actor.
  public static func capturing(_ captured: CapturedCommand) -> Self {
    .init(
      foregroundShell: { await captured.set($0) },
      backgroundShell: {
        await captured.set($0)
        return Data()
      }
    )
  }
}

public extension AsyncShellClient {
  static func withCapturingCommandClient(
    operation: () async throws -> Void,
    assert: ([ShellCommand]) async throws -> Void
  ) async throws {
    let captured = CapturedCommand()
    try await withDependencies {
      $0.asyncShellClient = .capturing(captured)
    } operation: {
      try await operation()
    }
    let commands = await captured.commands
    guard commands.count > 0 else {
      throw CapturingError.commandNotSet
    }
    try await assert(commands)
  }
}

enum CapturingError: Error {
  case commandNotSet
}
