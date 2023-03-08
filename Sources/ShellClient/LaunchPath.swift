import Foundation

public enum LaunchPath: CustomStringConvertible {
  case bash
  case csh
  case env
  case sh
  case tcsh
  case zsh
  case custom(path: any CustomStringConvertible, useDashC: Bool)
  
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
    case .bash, .csh, .sh, .tcsh, .zsh:
      return true
    case .env:
      return false
    case .custom(path: _, useDashC: let useDashC):
      return useDashC
    }
  }
  
  public var url: URL {
    if #available(macOS 13.0, *) {
      return .init(filePath: .init(stringLiteral: self.description))
    } else {
      // Fallback on earlier versions
      return .init(fileURLWithPath: self.description)
    }
  }
}
