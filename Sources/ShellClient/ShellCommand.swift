import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct ShellCommand {
  public var arguments: [any CustomStringConvertible]
  public var environment: [String: String]?
  public var launchPath: Shell
  public var workingDirectory: String?
  
  public init(
    shell: Shell = .env,
    environment: [String : String]? = nil,
    workingDirectory: String? = nil,
    arguments: [any CustomStringConvertible]
  ) {
    self.arguments = arguments
    self.environment = environment
    self.launchPath = shell
    self.workingDirectory = workingDirectory
  }
  
  public init<C: CustomStringConvertible>(
    shell: Shell = .env,
    environment: [String : String]? = nil,
    workingDirectory: String? = nil,
    _ arguments: C...
  ) {
    self.arguments = arguments
    self.environment = environment
    self.launchPath = shell
    self.workingDirectory = workingDirectory
  }
  
}
extension ShellCommand {
  
  public enum Shell: CustomStringConvertible {
    case bash(useDashC: Bool = true)
    case csh(useDashC: Bool = true)
    case custom(path: any CustomStringConvertible, useDashC: Bool)
    case env
    case sh(useDashC: Bool = true)
    case tcsh(useDashC: Bool = true)
    case zsh(useDashC: Bool = true)
    
    public static var bash: Self { .bash() }
    public static var csh: Self { .csh() }
    public static var sh: Self { .sh() }
    public static var tcsh: Self { .tcsh() }
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
    
    public var useDashC: Bool {
      switch self {
      case .env:
        return false
      case .custom(path: _, useDashC: let useDashC):
        return useDashC
      case .bash(useDashC: let usedashc):
        return usedashc
      case .csh(useDashC: let usedashc):
        return usedashc
      case .sh(useDashC: let usedashc):
        return usedashc
      case .tcsh(useDashC: let usedashc):
        return usedashc
      case .zsh(useDashC: let usedashc):
        return usedashc
      }
    }
    
    public var url: URL {
      #if os(Linux)
        return .init(fileURLWithPath: self.description)
      #else
      if #available(macOS 13.0, *) {
        return .init(filePath: .init(stringLiteral: self.description))
      } else {
        // Fallback on earlier versions
        return .init(fileURLWithPath: self.description)
      }
      #endif
    }
  }
}
