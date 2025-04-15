//
//  Logger.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import Foundation

struct Logger {
    // Logger for debugging and error handling that can be used throughout the app for consistent logging.
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        
        var emoji: String {
            switch self {
            case .debug: return "📋"
            case .info: return "📱"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
    
    static func log(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let output = "\(level.emoji) [\(level.rawValue)] [\(filename):\(line)] \(function): \(message)"
        print(output)
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}
