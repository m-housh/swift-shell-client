import XCTest
//import Dependencies
import ShellClient

final class SwiftShellClientTests: XCTestCase {
  
  #if !os(Linux)
  func test_foreground_shell() throws {
    try withDependencies {
      $0.logger = .liveValue
      $0.logger.logLevel = .debug
      $0.shellClient = .liveValue
    } operation: {
      @Dependency(\.shellClient) var shellClient

      let tmpDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("shell-test")
      
      try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: tmpDir) }
      
      let shells: [ShellCommand.Shell] = [.sh, .bash, .csh, .tcsh, .zsh]
     
      for shell in shells {
        
        let shellDescription = shell.description.split(separator: "/").last!
        
        let filePath = "fg-shell-\(shellDescription).txt"
        
        let command = ShellCommand(
          shell: shell,
          in: tmpDir.absoluteString,
          "echo \"Blob\" > \(filePath)"
        )
        
        try shellClient.foreground(command)
        
        let fileUrl = tmpDir.appendingPathComponent(filePath)
        
        let contents = try Data(contentsOf: fileUrl)
        let string = String(decoding: contents, as: UTF8.self)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print(string)
        XCTAssertEqual(string, "Blob")
      }
    }
  }
  
  func test_foreground_shell_async() async throws {
    try await withDependencies {
      $0.logger.logLevel = .debug
      $0.asyncShellClient = .liveValue
    } operation: {
      @Dependency(\.asyncShellClient) var shellClient

      let tmpDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("shell-test")
      
      try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: tmpDir) }
      
      let shells: [ShellCommand.Shell] = [.sh, .bash, .csh, .tcsh, .zsh]
      
      for shell in shells {
        
        let shellDescription = shell.description.split(separator: "/").last!
        
        let filePath = "fg-shell-\(shellDescription).txt"
        
        let command = ShellCommand(
          shell: shell,
          in: tmpDir.absoluteString,
          "echo \"Blob\" > \(filePath)"
        )
        
        try await shellClient.foreground(command)
        
        let fileUrl = tmpDir.appendingPathComponent(filePath)
        
        let contents = try Data(contentsOf: fileUrl)
        let string = String(decoding: contents, as: UTF8.self)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print(string)
        XCTAssertEqual(string, "Blob")
      }
    }
  }
  #endif
  
  func test_background_shell_with_array_literal_command() throws {
    try withDependencies {
      $0.logger.logLevel = .debug
      $0.shellClient.overrideBackgroundShell(with: Data("Foo".utf8))
    } operation: {
      @Dependency(\.shellClient) var shellClient
      
      let result = try shellClient
        .background(["foo", "bar"])
      
      XCTAssertEqual(result, "Foo")
    }
  }
  
  func test_background_shell_decoding() throws {
    let mock = Mock(value: "Blob")
    let data = try JSONEncoder().encode(mock)
    
    try withDependencies {
      $0.logger.logLevel = .debug
      $0.shellClient.overrideBackgroundShell(with: data)
    } operation: {
      @Dependency(\.shellClient) var shellClient
      
      let result = try shellClient.background(
          command: .init("foo", "bar"),
          as: Mock.self
        )
      
      XCTAssertEqual(result.value, "Blob")
    }
  }
  
  func test_async_background_shell() async throws {
    try await withDependencies {
      $0.logger.logLevel = .debug
      $0.asyncShellClient.overrideBackgroundShell(with: Data("Foo".utf8))
    } operation: {
      @Dependency(\.asyncShellClient) var shellClient
      
      let result = try await shellClient.background(.init("foo", "bar"))
      
      XCTAssertEqual(result, "Foo")
    }
  }
  
  func test_async_background_shell_decoding() async throws {
    let mock = Mock(value: "Blob")
    let data = try JSONEncoder().encode(mock)
    
    try await withDependencies {
      $0.logger.logLevel = .debug
      $0.asyncShellClient.overrideBackgroundShell(with: data)
    } operation: {
      @Dependency(\.asyncShellClient) var shellClient
      
      let result = try await shellClient.background(
          command: .init("foo", "bar"),
          as: Mock.self
        )
      
      XCTAssertEqual(result.value, "Blob")
    }
  }
  
  func test_echo() throws {
    try withDependencies {
      $0.logger = .liveValue
      $0.shellClient = .liveValue
    } operation: {
      try echo()
    }
    
    // Documentation Example
    func echo() throws {
      @Dependency(\.shellClient) var shellClient: ShellClient
      try shellClient.foreground(["echo", "Foo"])
      
      
      let output = try shellClient.background(
        ["echo", "Foo"],
        trimmingCharactersIn: .whitespacesAndNewlines
      )
      
      XCTAssertEqual(output, "Foo")
      
      let logger = basicLogger(.showing(label: "log".red))
      logger.info("blob")
    }
  }
  
  func test_echo_async() async throws {
    try await withDependencies {
      $0.logger = .liveValue
      $0.asyncShellClient = .liveValue
    } operation: {
      try await echo()
    }
    
    // Documentation Example
    func echo() async throws {
      @Dependency(\.asyncShellClient) var shell: AsyncShellClient
      
      try await shell.foreground(["echo", "Foo"])

      let output = try await shell.background(
        ["echo", "Foo"],
        trimmingCharactersIn: .whitespacesAndNewlines
      )

      XCTAssertEqual(output, "Foo")

      let osShell: ShellCommand.Shell
      #if os(Linux)
      osShell = ShellCommand.Shell.bash
      #else
      osShell = ShellCommand.Shell.zsh()
      #endif

      let data = try await shell.background(
        command: .init(shell: osShell, ["echo", #"'{"foo": "bar"}'"#]),
        as: [String: String].self
      )

      XCTAssertEqual(data["foo"], "bar")

      let logger = basicLogger(.showing(label: "log".red))
      logger.info("blob")
    }
  }
}

struct Mock: Codable {
  let value: String
}


