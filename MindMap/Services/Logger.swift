//
//  Logger.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation
import os.log

// MARK: - Log Levels
enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

// MARK: - Logger Categories
enum LogCategory: String, CaseIterable {
    case app = "App"
    case ui = "UI"
    case data = "Data"
    case network = "Network"
    case audio = "Audio"
    case speech = "Speech"
    case ai = "AI"
    case performance = "Performance"
    
    var osLog: OSLog {
        return OSLog(subsystem: "com.shape.MindMap", category: self.rawValue)
    }
}

// MARK: - App Logger
final class AppLogger {
    static let shared = AppLogger()
    
    private let maxLogEntries = 100 // Ограничение памяти
    private var logEntries: [LogEntry] = []
    private let queue = DispatchQueue(label: "com.mindmap.logger", qos: .utility)
    
    #if DEBUG
    private let minLogLevel: LogLevel = .debug
    #else
    private let minLogLevel: LogLevel = .info
    #endif
    
    private init() {}
    
    // MARK: - Log Entry
    struct LogEntry {
        let timestamp: Date
        let level: LogLevel
        let category: LogCategory
        let message: String
        let file: String
        let function: String
        let line: Int
        
        var formattedMessage: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            let timeString = formatter.string(from: timestamp)
            
            let fileName = (file as NSString).lastPathComponent
            return "\(level.emoji) [\(timeString)] [\(category.rawValue)] \(fileName):\(line) \(function) - \(message)"
        }
    }
    
    // MARK: - Logging Methods
    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level.rawValue >= minLogLevel.rawValue else { return }
        
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line
        )
        
        // Системное логирование
        os_log("%{public}@", log: category.osLog, type: level.osLogType, message)
        
        // Console логирование в DEBUG
        #if DEBUG
        print(entry.formattedMessage)
        #endif
        
        // Сохранение в память (с ограничением)
        queue.async { [weak self] in
            self?.addLogEntry(entry)
        }
    }
    
    private func addLogEntry(_ entry: LogEntry) {
        logEntries.append(entry)
        
        // Ограничиваем количество записей в памяти
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
    }
    
    // MARK: - Convenience Methods
    func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Performance Logging
    func measureTime<T>(
        operation: String,
        category: LogCategory = .performance,
        _ block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            log("⏱️ \(operation) took \(String(format: "%.3f", timeElapsed))s", level: .info, category: category)
        }
        return try block()
    }
    
    // MARK: - Get Logs
    func getRecentLogs(limit: Int = 50) -> [LogEntry] {
        return queue.sync {
            return Array(logEntries.suffix(limit))
        }
    }
    
    func clearLogs() {
        queue.async { [weak self] in
            self?.logEntries.removeAll()
        }
    }
}

// MARK: - Global Log Functions
func logDebug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.error(message, category: category, file: file, function: function, line: line)
}

func logCritical(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.critical(message, category: category, file: file, function: function, line: line)
}