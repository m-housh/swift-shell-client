import Cocoa
import ShellClient

try withDependencies {
  $0.logger = .liveValue
  $0.shellClient = .liveValue
} operation: {
  try echo()
}

func echo() throws {
  @Dependency(\.shellClient) var shell: ShellClient
  
  try shell.foreground(["echo", "Foo"])
}

print("Done.")
