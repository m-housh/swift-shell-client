import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Represents a command that can be run by a ``ShellClient`` or an ``AsyncShellClient``.
///
/// This type allows you to set / override variables in the process's environment.  The environment is
/// inherited by `ProcessInfo` and any variables that are set on a ``ShellCommand/environment``
/// variable will also be set in the environment or override a value if a key already is set in the `ProcessInfo`
/// environment.
///
public struct ShellCommand: Equatable, ExpressibleByArrayLiteral, Sendable {

  /// The default shell to use.
  public static let defaultShell = Shell.env()

  /// The arguments to pass to the shell program.
  public let arguments: [String]

  /// Any environment variables / overrides to set in the process environment.
  public let environment: [String: String]?

  /// The shell to use to run the command.
  public let shell: Shell

  /// Changes the working directory that the command runs in.
  public let workingDirectory: String?

  /// Access the working directory as a `URL` if set.
  public var workingDirectoryUrl: URL? {
    guard let workingDirectory else { return nil }
    return fileUrl(for: workingDirectory)
  }

  init(
    shell: Shell,
    environment: [String: String]?,
    in workingDirectory: String?,
    arguments: [String]
  ) {
    self.arguments = arguments
    self.environment = environment
    self.shell = shell
    self.workingDirectory = workingDirectory
  }

  /// Create a new ``ShellCommand`` instance.
  ///
  /// - Parameters:
  ///   - shell: The shell to use to run the command.
  ///   - environment: Environment variables / overrides for the command.
  ///   - workingDirectory: Change the working directory of the command.
  ///   - arguments: Arguments passed to the shell program.
  public init(
    shell: Shell = Self.defaultShell,
    environment: [String: String]? = nil,
    in workingDirectory: String? = nil,
    _ arguments: [String] = []
  ) {
    self.init(
      shell: shell,
      environment: environment,
      in: workingDirectory,
      arguments: arguments
    )
  }

  /// Create a new ``ShellCommand`` instance.
  ///
  /// - Parameters:
  ///   - shell: The shell to use to run the command.
  ///   - environment: Environment variables / overrides for the command.
  ///   - workingDirectory: Change the working directory of the command.
  ///   - arguments: Arguments passed to the shell program.
  public init(
    shell: Shell = Self.defaultShell,
    environment: [String: String]? = nil,
    in workingDirectory: String? = nil,
    _ arguments: String...
  ) {
    self.init(
      shell: shell,
      environment: environment,
      in: workingDirectory,
      arguments: arguments
    )
  }

}

// swiftlint:disable identifier_name
public extension ShellCommand {

  /// These represent the shell interpreter to run the ``ShellCommand``.
  ///
  /// This is a non-exhaustive list of shells that are on many `macOS` machines, however
  /// you can use a custom shell, if you use something different or want to not use a shell
  /// that is at one of the built-in paths (i.e. not in `/bin`).
  ///
  ///
  indirect enum Shell: CustomStringConvertible, Equatable, Sendable {

    /// Represents the `/bin/bash` shell interpreter.
    case bash(useDashC: Bool = true)

    /// Represents the `/bin/csh` shell interpreter.
    case csh(useDashC: Bool = true)

    /// Represents a customized shell interpreter.
    case custom(path: String, useDashC: Bool)

    /// Uses `/usr/bin/env` to find the shell interpreter.
    case env(Shell? = nil)

    /// Represents the `/bin/sh` shell interpreter
    case sh(useDashC: Bool = true)

    /// Represents the `/bin/tcsh` shell interpreter
    case tcsh(useDashC: Bool = true)

    /// Represents the `/bin/zsh` shell interpreter
    case zsh(useDashC: Bool = true)

    /// The default `/bin/bash` interpreter using `-c`.
    public static var bash: Self { .bash() }

    /// The default `/bin/csh` interpreter using `-c`.
    public static var csh: Self { .csh() }

    /// The default `/usr/bin/env` using `zsh` as the shell interpreter.
    public static var env: Self { .env() }

    /// The default `/bin/sh` interpreter using `-c`.
    public static var sh: Self { .sh() }

    /// The default `/bin/tcsh` interpreter using `-c`.
    public static var tcsh: Self { .tcsh() }

    /// The default `/bin/zsh` interpreter using `-c`.
    public static var zsh: Self { .zsh() }

    public var description: String {
      switch self {
      case .bash:
        return "/bin/bash"
      case .csh:
        return "/bin/csh"
      case .env:
        return "/usr/bin/env"
      case .sh:
        return "/bin/sh"
      case .tcsh:
        return "/bin/tcsh"
      case .zsh:
        return "/bin/zsh"
      case let .custom(path: path, useDashC: _):
        return path.description
      }
    }

    /// Represents the name of the shell interpreter.
    public var name: String {
      guard let lastComponent = description.split(separator: "/").last else {
        return description
      }
      return String(lastComponent)
    }

    /// Whether the shell interpreter should use a `-c` argument.
    public var useDashC: Bool {
      switch self {
      case .env:
        return false
      case .custom(path: _, useDashC: let useDashC):
        return useDashC
      case let .bash(useDashC: usedashc):
        return usedashc
      case let .csh(useDashC: usedashc):
        return usedashc
      case let .sh(useDashC: usedashc):
        return usedashc
      case let .tcsh(useDashC: usedashc):
        return usedashc
      case let .zsh(useDashC: usedashc):
        return usedashc
      }
    }

    /// Access the file url for the shell interpreter.
    public var url: URL {
      fileUrl(for: description)
    }
  }
}

// swiftlint:enable identifier_name

// MARK: - Equatable

public extension ShellCommand.Shell {
  static func == (lhs: ShellCommand.Shell, rhs: ShellCommand.Shell) -> Bool {
    return lhs.description == rhs.description
      && lhs.useDashC == rhs.useDashC
  }
}

public extension ShellCommand {
  static func == (lhs: ShellCommand, rhs: ShellCommand) -> Bool {
    return lhs.arguments.map(\.description) == rhs.arguments.map(\.description)
      && lhs.environment == rhs.environment
      && lhs.shell == rhs.shell
      && lhs.workingDirectory == rhs.workingDirectory
  }
}

// MARK: - ExpressibleByArrayLiteral

public extension ShellCommand {
  typealias ArrayLiteralElement = String

  init(arrayLiteral elements: String...) {
    self.init(elements)
  }
}

private func fileUrl(for string: String) -> URL {
  // Fallback on earlier versions
  return .init(fileURLWithPath: string)
}
