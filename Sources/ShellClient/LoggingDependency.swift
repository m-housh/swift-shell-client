import Dependencies
import Foundation
@_exported import Logging
import LoggingFormatAndPipe

extension Logger: DependencyKey {
  
  public static func basic(label: String) -> Self {
    Logger(label: label) { _ in
      LoggingFormatAndPipe.Handler(
        formatter: BasicFormatter([.message]),
        pipe: LoggerTextOutputStreamPipe.standardOutput
      )
    }
  }
  
  public static var liveValue: Logger {
    basic(label: "shell-client")
  }
  
  public static var testValue: Logger {
    basic(label: "shell-client-test")
  }
  
}

extension DependencyValues {
  public var logger: Logger {
    get { self[Logger.self] }
    set { self[Logger.self] = newValue }
  }
}
