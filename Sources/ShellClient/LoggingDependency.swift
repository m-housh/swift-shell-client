import Dependencies
import Foundation
@_exported import Logging
import LoggingFormatAndPipe

#if os(Linux)
  extension Logger: DependencyKey {

    /// Access a live `Logger` instance as a dependency, this logger does not show a label.
    ///
    /// ```swift
    /// @Dependency(\.logger) var logger
    /// ```
    public static var liveValue: Logger {
      basicLogger(.hidden(label: "shell-client"))
    }

    /// Access a test `Logger` instance as a dependency, this logger does show a label in red.
    ///
    /// ```swift
    /// @Dependency(\.logger) var logger
    /// ```
    public static var testValue: Logger {
      basicLogger(.showing(label: "shell-client-test".red))
    }
  }
#else
  extension Logger: @retroactive DependencyKey {

    /// Access a live `Logger` instance as a dependency, this logger does not show a label.
    ///
    /// ```swift
    /// @Dependency(\.logger) var logger
    /// ```
    public static var liveValue: Logger {
      basicLogger(.hidden(label: "shell-client"))
    }

    /// Access a test `Logger` instance as a dependency, this logger does show a label in red.
    ///
    /// ```swift
    /// @Dependency(\.logger) var logger
    /// ```
    public static var testValue: Logger {
      basicLogger(.showing(label: "shell-client-test".red))
    }

  }
#endif

/// Create a `Logger` instance that logs messages, optionally showing a label.
///
/// - Parameters:
///   - label: The label to use for the logger, optionally including it in log message.
public func basicLogger(_ label: Label) -> Logger {
  var formatters: [LogComponent] = [.message]
  if label.shouldShow {
    formatters.insert(.text(label.label), at: 0)
  }
  return Logger(label: label.label) { _ in
    LoggingFormatAndPipe.Handler(
      formatter: BasicFormatter(
        formatters,
        separator: " ▸ ".bold
      ),
      pipe: LoggerTextOutputStreamPipe.standardOutput
    )
  }
}

/// Represents a `Logger` label that can optionally be included in messages, when creating a logger using
/// the ``basicLogger(_:)`` function.
public enum Label {

  /// Show the label in the log message.
  case showing(label: any CustomStringConvertible)

  /// Don't show the label in the log message.
  case hidden(label: any CustomStringConvertible)

  fileprivate var label: String {
    switch self {
    case let .showing(label):
      return label.description
    case let .hidden(label):
      return label.description
    }
  }

  fileprivate var shouldShow: Bool {
    switch self {
    case .hidden:
      return false
    case .showing:
      return true
    }
  }
}

public extension DependencyValues {

  /// Access a `Logger` as a dependency.
  ///
  var logger: Logger {
    get { self[Logger.self] }
    set { self[Logger.self] = newValue }
  }
}
