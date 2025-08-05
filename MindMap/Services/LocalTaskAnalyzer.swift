//
//  LocalTaskAnalyzer.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation

// MARK: - Local Task Analyzer
class LocalTaskAnalyzer {
    static let shared = LocalTaskAnalyzer()
    
    private init() {}
    
    // MARK: - Analyze Text Locally
    func analyzeText(_ text: String) -> Task {
        logInfo("🧠 Локальный анализ текста: \(text.prefix(50))...", category: .ai)
        
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Извлекаем заголовок (первые 50 символов)
        let title = extractTitle(from: cleanText)
        
        // Определяем приоритет на основе ключевых слов
        let priority = determinePriority(from: cleanText)
        
        // Создаем подзадачи если есть списки
        let subtasks = extractSubtasks(from: cleanText)
        
        // Создаем описание если текст длиннее заголовка
        let description = cleanText.count > title.count ? cleanText : nil
        
        let task = Task(
            title: title,
            description: description,
            priority: priority,
            audioFilePath: nil,
            originalText: cleanText,
            subtasks: subtasks
        )
        
        logInfo("✅ Создана задача: \(task.title)", category: .ai)
        return task
    }
    
    // MARK: - Extract Title
    private func extractTitle(from text: String) -> String {
        // Ищем первое предложение или первые 50 символов
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        if let firstSentence = sentences.first, !firstSentence.isEmpty {
            let title = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
            return title.count > 50 ? String(title.prefix(50)) : title
        }
        
        // Если нет предложений, берем первые 50 символов
        return String(text.prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Determine Priority  
    private func determinePriority(from text: String) -> TaskPriority {
        let lowercaseText = text.lowercased()
        
        // Высокий приоритет
        let highPriorityKeywords = [
            "срочно", "важно", "критично", "немедленно", "сегодня",
            "deadline", "дедлайн", "до завтра", "горит", "асап",
            "приоритет", "неотложно", "экстренно"
        ]
        
        // Низкий приоритет
        let lowPriorityKeywords = [
            "когда-нибудь", "не спешно", "при возможности", 
            "свободное время", "досуг", "развлечение",
            "почитать", "посмотреть", "изучить"
        ]
        
        for keyword in highPriorityKeywords {
            if lowercaseText.contains(keyword) {
                logDebug("🔴 Высокий приоритет найден по ключевому слову: \(keyword)", category: .ai)
                return .high
            }
        }
        
        for keyword in lowPriorityKeywords {
            if lowercaseText.contains(keyword) {
                logDebug("🟢 Низкий приоритет найден по ключевому слову: \(keyword)", category: .ai)
                return .low
            }
        }
        
        // Проверяем на даты (завтра, через неделю и т.д.)
        if containsDateReferences(lowercaseText) {
            logDebug("🟡 Средний приоритет из-за упоминания дат", category: .ai)
            return .medium
        }
        
        // По умолчанию средний приоритет
        return .medium
    }
    
    // MARK: - Extract Subtasks
    private func extractSubtasks(from text: String) -> [Subtask] {
        var subtasks: [Subtask] = []
        
        // Ищем списки с разными форматами
        let listPatterns = [
            "\\d+\\s*[.):]\\s*([^\n\r]+)",  // 1. задача, 1) задача, 1: задача
            "[-•*]\\s*([^\n\r]+)",         // - задача, • задача, * задача
            "\\n\\s*([А-Яа-я][^\n\r]*(?:купить|сделать|позвонить|написать|отправить|проверить)[^\n\r]*)" // строки с глаголами действия
        ]
        
        for pattern in listPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if match.numberOfRanges > 1 {
                        if let range = Range(match.range(at: 1), in: text) {
                            let subtaskText = String(text[range])
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !subtaskText.isEmpty && subtaskText.count > 3 {
                                subtasks.append(Subtask(title: subtaskText))
                            }
                        }
                    }
                }
            } catch {
                logError("❌ Ошибка regex для подзадач: \(error)", category: .ai)
            }
        }
        
        // Ограничиваем до 5 подзадач
        if subtasks.count > 5 {
            subtasks = Array(subtasks.prefix(5))
        }
        
        if !subtasks.isEmpty {
            logDebug("📋 Найдено подзадач: \(subtasks.count)", category: .ai)
        }
        
        return subtasks
    }
    
    // MARK: - Date References
    private func containsDateReferences(_ text: String) -> Bool {
        let dateKeywords = [
            "завтра", "сегодня", "вчера", "на неделе", "в понедельник",
            "во вторник", "в среду", "в четверг", "в пятницу", 
            "в субботу", "в воскресенье", "через", "до", "после"
        ]
        
        for keyword in dateKeywords {
            if text.contains(keyword) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Task Creation Extension
extension Task {
    static func createFromText(_ text: String) -> Task {
        return LocalTaskAnalyzer.shared.analyzeText(text)
    }
}