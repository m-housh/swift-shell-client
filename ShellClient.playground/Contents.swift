import Cocoa
import Dependencies
import ShellClient

var greeting = "Hello, playground"

let shellClient = withDependencies({
  $0.logger.logLevel = .debug
}, operation: {
  return ShellClient.liveValue
})

try shellClient.foregroundShell(shell: .bash, "echo", "Foo", ">", "/tmp/bar.txt")
