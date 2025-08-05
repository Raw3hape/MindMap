//
//  SpeechRecognitionService.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition Service
@MainActor
class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecognizing = false
    @Published var transcribedText = ""
    
    private init() {
        // Инициализация для русского языка
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        
        logInfo("🎤 SpeechRecognition инициализирован для русского языка", category: .speech)
        logInfo("🌍 Доступность: \(speechRecognizer?.isAvailable ?? false)", category: .speech)
    }
    
    // MARK: - Permission Handling
    func requestPermissions() async -> Bool {
        // Проверяем разрешение на распознавание речи
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard speechStatus == .authorized else {
            logError("❌ Нет разрешения на распознавание речи: \(speechStatus)", category: .speech)
            return false
        }
        
        // Проверяем разрешение на микрофон
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { status in
                continuation.resume(returning: status)
            }
        }
        
        guard audioStatus else {
            logError("❌ Нет разрешения на микрофон", category: .speech)
            return false
        }
        
        logInfo("✅ Все разрешения получены", category: .speech)
        return true
    }
    
    // MARK: - Transcribe Audio File
    func transcribeAudioFile(at url: URL) async throws -> String {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        logInfo("🎵 Начинаем транскрипцию файла: \(url.lastPathComponent)", category: .speech)
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        // Проверяем доступность офлайн режима
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
            logInfo("🔒 Используем офлайн распознавание", category: .speech)
        } else {
            request.requiresOnDeviceRecognition = false
            logInfo("🌐 Используем онлайн распознавание", category: .speech)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                guard !hasResumed else { return }
                
                if let error = error {
                    let nsError = error as NSError
                    logError("❌ Ошибка транскрипции: \(error.localizedDescription) (код: \(nsError.code))", category: .speech)
                    
                    // Если это ошибка локального распознавания, пробуем онлайн
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
                        logInfo("🔄 Переключаемся на онлайн распознавание", category: .speech)
                        hasResumed = true
                        
                        // Создаем новый запрос без офлайн режима
                        let onlineRequest = SFSpeechURLRecognitionRequest(url: url)
                        onlineRequest.shouldReportPartialResults = false
                        onlineRequest.requiresOnDeviceRecognition = false
                        
                        speechRecognizer.recognitionTask(with: onlineRequest) { onlineResult, onlineError in
                            if let onlineError = onlineError {
                                continuation.resume(throwing: onlineError)
                                return
                            }
                            
                            if let onlineResult = onlineResult, onlineResult.isFinal {
                                let text = onlineResult.bestTranscription.formattedString
                                logInfo("✅ Онлайн транскрипция завершена: \(text.prefix(100))...", category: .speech)
                                continuation.resume(returning: text)
                            }
                        }
                    } else {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                    return
                }
                
                if let result = result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    logInfo("✅ Транскрипция завершена: \(text.prefix(100))...", category: .speech)
                    hasResumed = true
                    continuation.resume(returning: text)
                }
            }
        }
    }
    
    // MARK: - Real-time Recognition
    func startRealTimeRecognition() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        if audioEngine.isRunning {
            stopRealTimeRecognition()
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        // Используем офлайн режим только если он доступен
        if speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
            logInfo("🔒 Реальное время: офлайн режим", category: .speech)
        } else {
            recognitionRequest.requiresOnDeviceRecognition = false
            logInfo("🌐 Реальное время: онлайн режим", category: .speech)
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecognizing = true
        transcribedText = ""
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                logError("❌ Ошибка реального времени: \(error.localizedDescription)", category: .speech)
                DispatchQueue.main.async {
                    self.stopRealTimeRecognition()
                }
            }
        }
        
        logInfo("🎤 Запущено распознавание в реальном времени", category: .speech)
    }
    
    func stopRealTimeRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecognizing = false
        
        logInfo("⏹️ Остановлено распознавание в реальном времени", category: .speech)
    }
    
    // MARK: - Check Availability
    var isOnDeviceRecognitionAvailable: Bool {
        speechRecognizer?.supportsOnDeviceRecognition ?? false
    }
    
    var isSpeechRecognitionAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }
}

// MARK: - Errors
enum SpeechRecognitionError: LocalizedError {
    case recognizerUnavailable
    case requestCreationFailed
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Распознавание речи недоступно"
        case .requestCreationFailed:
            return "Не удалось создать запрос на распознавание"
        case .recognitionFailed(let message):
            return "Ошибка распознавания: \(message)"
        }
    }
}

