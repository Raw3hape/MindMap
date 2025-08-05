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

// MARK: - OpenAI Service
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private let baseURL = "https://your-vercel-app.vercel.app" // Замените на ваш URL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Process Audio
    func processAudio(from audioURL: URL) async throws -> Task {
        // Конвертируем аудио в данные
        let audioData = try Data(contentsOf: audioURL)
        let base64Audio = audioData.base64EncodedString()
        
        // Подготавливаем запрос
        let request = ProcessAudioRequest(
            audioData: base64Audio,
            mimeType: "audio/m4a"
        )
        
        // Создаем URL запрос
        guard let url = URL(string: "\(baseURL)/api/process-audio") else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw OpenAIError.encodingError
        }
        
        // Выполняем запрос
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OpenAIError.serverError(httpResponse.statusCode)
            }
            
            let processResponse = try JSONDecoder().decode(ProcessAudioResponse.self, from: data)
            
            if processResponse.success, let taskData = processResponse.data {
                return convertToTask(from: taskData, audioURL: audioURL)
            } else {
                throw OpenAIError.processingError(processResponse.error ?? "Неизвестная ошибка")
            }
            
        } catch {
            if error is OpenAIError {
                throw error
            } else {
                throw OpenAIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Process Text
    func processText(_ text: String) async throws -> Task {
        guard let url = URL(string: "\(baseURL)/api/process-text") else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["text": text]
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.encodingError
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OpenAIError.serverError(httpResponse.statusCode)
            }
            
            let processResponse = try JSONDecoder().decode(ProcessAudioResponse.self, from: data)
            
            if processResponse.success, let taskData = processResponse.data {
                return convertToTask(from: taskData, audioURL: nil)
            } else {
                throw OpenAIError.processingError(processResponse.error ?? "Неизвестная ошибка")
            }
            
        } catch {
            if error is OpenAIError {
                throw error
            } else {
                throw OpenAIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func convertToTask(from response: OpenAITaskResponse, audioURL: URL?) -> Task {
        let priority = TaskPriority.allCases.first { $0.displayName.lowercased() == response.priority.lowercased() } ?? .medium
        
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
}

// MARK: - OpenAI Errors
enum OpenAIError: LocalizedError {
    case invalidURL
    case encodingError
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