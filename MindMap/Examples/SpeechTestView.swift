//
//  SpeechTestView.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct SpeechTestView: View {
    @StateObject private var speechService = SpeechRecognitionService.shared
    @State private var transcriptionResult = ""
    @State private var isTestingFile = false
    @State private var testAudioURL: URL?
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Статус доступности
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: speechService.isSpeechRecognitionAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(speechService.isSpeechRecognitionAvailable ? .green : .red)
                        
                        Text(speechService.isSpeechRecognitionAvailable ? "Доступен" : "Недоступен")
                    }
                    .font(.headline)
                    
                    if speechService.isOnDeviceRecognitionAvailable {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.blue)
                            Text("Поддерживает офлайн режим")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Результаты транскрипции
                if !transcriptionResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Результат:")
                            .font(.headline)
                        
                        ScrollView {
                            Text(transcriptionResult)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                // Реальное время
                VStack(spacing: 12) {
                    Text("Тест в реальном времени")
                        .font(.headline)
                    
                    if speechService.isRecognizing {
                        VStack {
                            Text("Слушаю...")
                                .foregroundColor(.red)
                            
                            if !speechService.transcribedText.isEmpty {
                                Text(speechService.transcribedText)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    
                    Button(speechService.isRecognizing ? "Остановить" : "Начать говорить") {
                        if speechService.isRecognizing {
                            speechService.stopRealTimeRecognition()
                            transcriptionResult = speechService.transcribedText
                        } else {
                            startRealTimeRecognition()
                        }
                    }
                    .padding()
                    .background(speechService.isRecognizing ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Тест с аудио файлом
                VStack(spacing: 12) {
                    Text("Тест с аудио файлом")
                        .font(.headline)
                    
                    Button("Выбрать и протестировать файл") {
                        // TODO: Добавить выбор файла
                        testWithSampleText()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isTestingFile)
                    
                    if isTestingFile {
                        ProgressView("Обрабатываем...")
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Тест Speech Recognition")
            .alert("Ошибка", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startRealTimeRecognition() {
        do {
            try speechService.startRealTimeRecognition()
        } catch {
            showErrorMessage("Ошибка запуска: \(error.localizedDescription)")
        }
    }
    
    private func testWithSampleText() {
        // Для тестирования создадим задачу из примера текста
        let sampleText = "Срочно купить молоко и хлеб до завтра"
        transcriptionResult = "Тест локального анализатора:\n\nИсходный текст: \(sampleText)\n\n"
        
        let task = LocalTaskAnalyzer.shared.analyzeText(sampleText)
        
        transcriptionResult += "Результат анализа:\n"
        transcriptionResult += "• Заголовок: \(task.title)\n"
        transcriptionResult += "• Приоритет: \(task.priority.displayName)\n"
        
        if let description = task.description {
            transcriptionResult += "• Описание: \(description)\n"
        }
        
        if !task.subtasks.isEmpty {
            transcriptionResult += "• Подзадачи:\n"
            for subtask in task.subtasks {
                transcriptionResult += "  - \(subtask.title)\n"
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    SpeechTestView()
}