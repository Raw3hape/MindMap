//
//  RecordingViewModel.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation
import Combine
import SwiftUI
import Speech

// MARK: - Recording View Model
@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingLevel: Float = 0
    @Published var manualText = ""
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var processingMode: ProcessingMode = .speechOnly
    @Published var useOfflineProcessing = true
    @Published var speechRecognitionAvailable = false
    
    private let audioManager = AudioManager.shared
    private let openAIService = OpenAIService.shared
    private let speechService = SpeechRecognitionService.shared
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentRecordingURL: URL?
    
    init() {
        setupBindings()
        checkSpeechAvailability()
    }
    
    private func setupBindings() {
        // Привязываем состояние записи
        audioManager.$recordingState
            .map { state in
                switch state {
                case .recording:
                    return true
                default:
                    return false
                }
            }
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        // Привязываем длительность записи
        audioManager.$recordingDuration
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)
        
        // Привязываем уровень звука
        audioManager.$recordingLevel
            .assign(to: \.recordingLevel, on: self)
            .store(in: &cancellables)
        
        // Привязываем режим обработки
        $processingMode
            .sink { [weak self] mode in
                self?.openAIService.setProcessingMode(mode)
            }
            .store(in: &cancellables)
        
        // Привязываем офлайн режим
        $useOfflineProcessing
            .sink { [weak self] enabled in
                self?.openAIService.setOfflineFirst(enabled)
            }
            .store(in: &cancellables)
    }
    
    private func checkSpeechAvailability() {
        _Concurrency.Task {
            let hasPermissions = await speechService.requestPermissions()
            await MainActor.run {
                speechRecognitionAvailable = hasPermissions && speechService.isSpeechRecognitionAvailable
                logInfo("🎤 Speech Recognition доступен: \(speechRecognitionAvailable)", category: .speech)
            }
        }
    }
    
    // MARK: - Recording Actions
    func startRecording() {
        guard audioManager.hasPermission else {
            showErrorMessage("Нет разрешения на запись аудио")
            return
        }
        
        currentRecordingURL = audioManager.startRecording()
        if currentRecordingURL == nil {
            showErrorMessage("Не удалось начать запись")
        }
    }
    
    func stopRecording() {
        audioManager.stopRecording()
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // MARK: - Processing
    func processRecording() async {
        await processRecordingWithMode(processingMode)
    }
    
    func processRecordingWithMode(_ mode: ProcessingMode) async {
        guard let audioURL = currentRecordingURL else {
            showErrorMessage("Нет записи для обработки")
            return
        }
        
        isProcessing = true
        
        do {
            let task = try await openAIService.processAudioWithMode(from: audioURL, mode: mode)
            coreDataManager.createTask(task)
            
            // Очищаем данные после успешной обработки
            clearRecording()
            
        } catch {
            showErrorMessage("Ошибка обработки записи: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    func processManualText() async {
        guard !manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorMessage("Введите текст для обработки")
            return
        }
        
        isProcessing = true
        
        do {
            let task = try await openAIService.processText(manualText)
            coreDataManager.createTask(task)
            
            // Очищаем текст после успешной обработки
            manualText = ""
            
        } catch {
            showErrorMessage("Ошибка обработки текста: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    // MARK: - Utility
    func clearRecording() {
        if let url = currentRecordingURL {
            audioManager.deleteRecording(at: url)
        }
        currentRecordingURL = nil
        recordingDuration = 0
        recordingLevel = 0
    }
    
    func playRecording() {
        guard let url = currentRecordingURL else { return }
        audioManager.playAudio(from: url)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        audioManager.formatDuration(duration)
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Validation
    var hasRecording: Bool {
        currentRecordingURL != nil && recordingDuration > 0
    }
    
    var hasManualText: Bool {
        !manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canProcess: Bool {
        !isProcessing && (hasRecording || hasManualText)
    }
    
    // MARK: - Processing Mode Helpers
    func getRecommendedMode() -> ProcessingMode {
        // Всегда рекомендуем только iOS Speech
        return .speechOnly
    }
    
    func switchToRecommendedMode() {
        let recommended = getRecommendedMode()
        if recommended != processingMode {
            processingMode = recommended
        }
    }
    
    var processingModeDescription: String {
        switch processingMode {
        case .speechOnly:
            return "iOS Speech + локальная обработка"
        case .auto:
            return "Автоматический выбор"
        }
    }
}