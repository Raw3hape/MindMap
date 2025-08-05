//
//  RecordingViewModel.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation
import Combine
import SwiftUI

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
    
    private let audioManager = AudioManager.shared
    private let openAIService = OpenAIService.shared
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentRecordingURL: URL?
    
    init() {
        setupBindings()
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
        guard let audioURL = currentRecordingURL else {
            showErrorMessage("Нет записи для обработки")
            return
        }
        
        isProcessing = true
        
        do {
            let task = try await openAIService.processAudio(from: audioURL)
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
}