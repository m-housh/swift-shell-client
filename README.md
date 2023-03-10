# swift-shell-client

[![CI](https://github.com/m-housh/swift-shell-client/actions/workflows/ci.yml/badge.svg)](https://github.com/m-housh/swift-shell-client/actions/workflows/ci.yml)

A package that allows you to run shell scripts from your
swift code.

[Github Repository](https://github.com/m-housh/swift-shell-client)
[Documentation](https://m-housh.github.io/swift-shell-client/documentation/shellclient)

## Usage

You can include in your project, by using swift package manager.

```swift
import PackageDescription

let package = Package(
  ...
  dependencies: [
    .package(url: "https://github.com/m-housh/swift-shell-client.git", from: "0.1.0"),
    ...
  ],
  targets: [
    .target(
      name: "MyTarget",
      dependencies: [
        .product(name: "ShellClient", package: "swift-shell-client"),
      ]
    ),
    ...
  ]
)
```

### Basic Usage

You access a shell client through the 
[swift-dependencies](https://github.com/pointfreeco/swift-dependencies) system.  

```swift
import ShellClient

func echo() throws {
  @Dependency(\.logger) var logger
  @Dependency(\.shellClient) var shell

  try shell.foreground(["echo", "Foo"])

  // Or run in a background process, and capture the output.

  let output = try shell.background(
    ["echo", "world"]
    trimmingCharactersIn: .whitespacesAndNewlines
  )

  logger.info("Hello \(output)!")

}

func echoAsync() async throws {
  @Dependency(\.logger) var logger
  @Dependency(\.asyncShellClient) var shell

  try await shell.foreground(["echo", "Foo"])

  // Or run in a background process, and capture the output.

  let output = try await shell.background(
    ["echo", "world"],
    trimmingCharactersIn: .whitespacesAndNewlines
  )

  logger.info("Hello \(output)!")

}

try echo()
try await echoAsync()

```

### Logging

We use [swift-log](https://github.com/apple/swift-log) along with
[swift-log-format-and-pipe](https://github.com/adorkable/swift-log-format-and-pipe.git) to create
a basic logger that you have access to.  You can also use 
[Rainbow](https://github.com/onevcat/Rainbow) for color text output to the terminal.

The built-in logger will just log messages without any label when built in release and will 
log with the label `shell-client` when in debug or testing context.

You can create a basic logger with a label by using the following method provided by the
library.

```swift
import Rainbow

let logger = basicLogger(.showing(label: "log".red))

logger.info("blob")
// log ▸ blob
```

## Documentation

You can read the full [documentation](https://m-housh.github.io/swift-shell-client/documentation/shellclient)
here.
