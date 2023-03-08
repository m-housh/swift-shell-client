import XCTest
import Dependencies
import ShellClient

final class SwiftShellClientTests: XCTestCase {
  
//  func test_foreground_shell() throws {
//    try withDependencies {
//      $0.shellClient = .liveValue
//    } operation: {
//      @Dependency(\.shellClient) var shellClient
//
//    }
//  }

  func test_background_shell() throws {
    try withDependencies {
      $0.logger.logLevel = .debug
      $0.shellClient.overrideBackgroundShell(with: Data("Foo".utf8))
    } operation: {
      @Dependency(\.shellClient) var shellClient
      
      let result = try shellClient
        .backgroundShell("foo", "bar")
      
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
      
      let result = try shellClient
        .backgroundShell(
          as: Mock.self,
          "foo", "bar"
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
      
      let result = try await shellClient
        .backgroundShell("foo", "bar")
      
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
      
      let result = try await shellClient
        .backgroundShell(
          as: Mock.self,
          "foo", "bar"
        )
      
      XCTAssertEqual(result.value, "Blob")
    }
  }
  
}

struct Mock: Codable {
  let value: String
}


