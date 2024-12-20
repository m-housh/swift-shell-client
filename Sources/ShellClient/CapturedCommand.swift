/// Used to capture the command that would be run for a live client implementation.
///
/// This is useful for testing purposes.
public actor CapturedCommand: Sendable {
  public private(set) var command: ShellCommand?

  public init() {}

  func set(_ command: ShellCommand) {
    self.command = command
  }
}
