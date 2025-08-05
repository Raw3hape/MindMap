//
//  OpenAIService.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation
import AVFoundation

// MARK: - OpenAI Response Models
struct OpenAITaskResponse: Codable {
    let title: String
    let description: String?
    let priority: String
    let subtasks: [String]
    let originalText: String
}

struct ProcessAudioRequest: Codable {
    let audioData: String // Base64 encoded audio
    let mimeType: String
}

struct ProcessAudioResponse: Codable {
    let success: Bool
    let data: OpenAITaskResponse?
    let error: String?
}

// MARK: - Processing Mode
enum ProcessingMode: CaseIterable {
    case speechOnly       // Только iOS Speech Framework + текстовый анализ
    case auto             // Умный выбор (пока только Speech)
    
    var displayName: String {
        switch self {
        case .speechOnly:
            return "iOS Speech + GPT"
        case .auto:
            return "Автоматический"
        }
    }
    
    var description: String {
        switch self {
        case .speechOnly:
            return "Использует iOS Speech Framework + GPT анализ текста"
        case .auto:
            return "Автоматически выбирает лучший метод"
        }
    }
}

// MARK: - OpenAI Service
@MainActor
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    @Published var processingMode: ProcessingMode = .speechOnly
    @Published var useOfflineFirst: Bool = true
    
    private let baseURL = "https://mind-map-tau-roan.vercel.app" // Production URL - работает!
    private let session = URLSession.shared
    private let speechService = SpeechRecognitionService.shared
    private let localAnalyzer = LocalTaskAnalyzer.shared
    
    private init() {}
    
    // MARK: - Process Audio with Hybrid Approach
    func processAudio(from audioURL: URL) async throws -> Task {
        return try await processAudioWithMode(from: audioURL, mode: processingMode)
    }
    
    func processAudioWithMode(from audioURL: URL, mode: ProcessingMode) async throws -> Task {
        logInfo("🎤 Начинаем обработку аудио файла с режимом: \(mode)", category: .audio)
        
        // Всегда используем iOS Speech Framework + GPT анализ
        switch mode {
        case .speechOnly, .auto:
            return try await processAudioWithSpeechFramework(from: audioURL)
        }
    }
    
    // MARK: - Speech Framework Processing
    private func processAudioWithSpeechFramework(from audioURL: URL) async throws -> Task {
        logInfo("🗣️ Используем iOS Speech Framework", category: .speech)
        
        let transcription = try await speechService.transcribeAudioFile(at: audioURL)
        logInfo("✅ Транскрипция получена: \(transcription.prefix(50))...", category: .speech)
        
        // Отправляем текст на анализ через API
        return try await processTextViaAPI(transcription, audioURL: audioURL)
    }
    
    
    
    // MARK: - Process Text
    func processText(_ text: String) async throws -> Task {
        return try await processTextViaAPI(text, audioURL: nil)
    }
    
    // MARK: - API Text Processing with Fallback
    private func processTextViaAPI(_ text: String, audioURL: URL?) async throws -> Task {
        // Сначала пробуем API
        do {
            logInfo("🌐 Пробуем отправить текст на анализ через API", category: .network)
            return try await processTextWithAPI(text, audioURL: audioURL)
        } catch {
            // При ошибке API используем локальный анализ
            logInfo("📱 API недоступен, используем локальный анализатор", category: .network) 
            let localTask = localAnalyzer.analyzeText(text)
            
            // Добавляем путь к аудио файлу если есть
            if let audioURL = audioURL {
                return Task(
                    title: localTask.title,
                    description: localTask.description,
                    priority: localTask.priority,
                    audioFilePath: audioURL.path,
                    originalText: text,
                    subtasks: localTask.subtasks
                )
            } else {
                return localTask
            }
        }
    }
    
    // MARK: - API Text Processing
    private func processTextWithAPI(_ text: String, audioURL: URL?) async throws -> Task {
        let requestBody = ["text": text]
        let fullURL = "\(baseURL)/api/process-text"
        
        guard let url = URL(string: fullURL) else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.encodingError
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        logInfo("📡 Получен ответ от API: статус \(httpResponse.statusCode)", category: .network)
        
        if httpResponse.statusCode != 200 {
            let errorData = String(data: data, encoding: .utf8) ?? "No error data"
            logError("❌ Ошибка API \(httpResponse.statusCode): \(errorData)", category: .network)
            throw OpenAIError.serverError(httpResponse.statusCode)
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No data"
        logInfo("📦 Сырой ответ API: \(responseString)", category: .network)
        
        do {
            let processResponse = try JSONDecoder().decode(ProcessAudioResponse.self, from: data)
            logInfo("✅ Успешно декодирован ответ: \(processResponse.success)", category: .network)
            
            if processResponse.success, let taskData = processResponse.data {
                let task = convertToTask(from: taskData, audioURL: audioURL)
                logInfo("🎯 Создана задача через API: \(task.title)", category: .network)
                return task
            } else {
                logError("❌ API вернул ошибку: \(processResponse.error ?? "Неизвестная ошибка")", category: .network)
                throw OpenAIError.processingError(processResponse.error ?? "Неизвестная ошибка")
            }
        } catch {
            logError("❌ Ошибка декодирования JSON: \(error)", category: .network)
            throw OpenAIError.decodingError
        }
    }
    
    // MARK: - Configuration Methods
    func setProcessingMode(_ mode: ProcessingMode) {
        processingMode = mode
        logInfo("⚙️ Режим обработки изменен на: \(mode)", category: .audio)
    }
    
    func setOfflineFirst(_ enabled: Bool) {
        useOfflineFirst = enabled
        logInfo("📱 Офлайн-первый режим: \(enabled ? "включен" : "выключен")", category: .audio)
    }
    
    func getSpeechRecognitionAvailability() -> Bool {
        return speechService.isSpeechRecognitionAvailable
    }
    
    func getRecommendedMode(for audioURL: URL) -> ProcessingMode {
        // Всегда рекомендуем iOS Speech + GPT анализ
        return .speechOnly
    }
    
    // MARK: - Helper Methods
    private func convertToTask(from response: OpenAITaskResponse, audioURL: URL?) -> Task {
        let priority = mapPriority(from: response.priority)
        
        let subtasks = response.subtasks.map { title in
            Subtask(title: title)
        }
        
        return Task(
            title: response.title,
            description: response.description,
            priority: priority,
            audioFilePath: audioURL?.path,
            originalText: response.originalText,
            subtasks: subtasks
        )
    }
    
    private func mapPriority(from priorityString: String) -> TaskPriority {
        let lowercased = priorityString.lowercased()
        
        // Маппинг возможных вариантов от OpenAI
        switch lowercased {
        case "low", "низкий", "1":
            return .low
        case "high", "urgent", "важный", "высокий", "3":
            return .high
        case "medium", "normal", "средний", "2":
            return .medium
        default:
            return .medium
        }
    }
}

// MARK: - OpenAI Errors
enum OpenAIError: LocalizedError {
    case invalidURL
    case encodingError
    case decodingError
    case invalidResponse
    case serverError(Int)
    case processingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .decodingError:
            return "Ошибка декодирования ответа"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .processingError(let message):
            return "Ошибка обработки: \(message)"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        }
    }
}