//
//  RecordingView.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingProcessingAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновый градиент
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Заголовок
                        headerSection
                        
                        // Секция записи
                        recordingSection
                        
                        // Или разделитель
                        dividerSection
                        
                        // Секция текстового ввода
                        textInputSection
                        
                        // Кнопка обработки
                        processButton
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.text)
                }
            }
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Произошла неизвестная ошибка")
        }
        .alert("Обработка", isPresented: $showingProcessingAlert) {
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Обрабатываем вашу задачу...")
        }
        .onChange(of: viewModel.isProcessing) { isProcessing in
            showingProcessingAlert = isProcessing
            if !isProcessing && !viewModel.showError {
                // Если обработка завершилась успешно, закрываем экран
                dismiss()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary)
            
            Text("Создайте задачу")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.text)
            
            Text("Запишите голосовое сообщение или введите текст")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Recording Section
    private var recordingSection: some View {
        VStack(spacing: 20) {
            // Визуализация записи
            recordingVisualization
            
            // Кнопка записи
            recordingButton
            
            // Информация о записи
            if viewModel.hasRecording {
                recordingInfo
            }
        }
        .padding(.vertical, 20)
    }
    
    private var recordingVisualization: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .fill(AppColors.recordingBackground)
                .frame(width: 200, height: 200)
            
            // Анимированные круги при записи
            if viewModel.isRecording {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(AppColors.recordingActive.opacity(0.3), lineWidth: 2)
                        .frame(width: 200 + CGFloat(index * 30), height: 200 + CGFloat(index * 30))
                        .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                        .opacity(viewModel.isRecording ? 0.3 : 0.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: viewModel.isRecording
                        )
                }
            }
            
            // Центральная визуализация уровня звука
            Circle()
                .fill(AppColors.recordingGradient)
                .frame(
                    width: 100 + CGFloat(viewModel.recordingLevel * 50),
                    height: 100 + CGFloat(viewModel.recordingLevel * 50)
                )
                .animation(.easeInOut(duration: 0.1), value: viewModel.recordingLevel)
            
            // Иконка микрофона
            Image(systemName: viewModel.isRecording ? "mic.fill" : "mic")
                .font(.system(size: 30))
                .foregroundColor(.white)
        }
    }
    
    private var recordingButton: some View {
        Button(action: viewModel.toggleRecording) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                    .font(.title2)
                
                Text(viewModel.isRecording ? "Остановить" : "Записать")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(viewModel.isRecording ? AppColors.error : AppColors.primary)
            )
            .scaleEffect(viewModel.isRecording ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
        }
        .disabled(viewModel.isProcessing)
    }
    
    private var recordingInfo: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(AppColors.textSecondary)
                Text(viewModel.formatDuration(viewModel.recordingDuration))
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.text)
            }
            
            HStack(spacing: 12) {
                Button(action: viewModel.playRecording) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle")
                        Text("Прослушать")
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.primary)
                }
                
                Button(action: viewModel.clearRecording) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Удалить")
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.error)
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
            
            Text("ИЛИ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
    }
    
    // MARK: - Text Input Section
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.cursor")
                    .foregroundColor(AppColors.primary)
                Text("Введите текст задачи")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.text)
                Spacer()
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.surface)
                    .stroke(AppColors.border, lineWidth: 1)
                    .frame(minHeight: 120)
                
                if viewModel.manualText.isEmpty {
                    Text("Опишите вашу задачу...")
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $viewModel.manualText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .foregroundColor(AppColors.text)
            }
            
            if viewModel.hasManualText {
                HStack {
                    Spacer()
                    Text("\(viewModel.manualText.count) символов")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Process Button
    private var processButton: some View {
        Button(action: processTask) {
            HStack(spacing: 12) {
                if viewModel.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                }
                
                Text(viewModel.isProcessing ? "Обрабатываем..." : "Создать задачу")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(viewModel.canProcess ? AppColors.primary : AppColors.textTertiary)
            )
            .scaleEffect(viewModel.canProcess ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canProcess)
        }
        .disabled(!viewModel.canProcess)
    }
    
    // MARK: - Actions
    private func processTask() {
        Task {
            if viewModel.hasRecording {
                await viewModel.processRecording()
            } else if viewModel.hasManualText {
                await viewModel.processManualText()
            }
        }
    }
}

#Preview {
    RecordingView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    RecordingView()
        .preferredColorScheme(.dark)
}