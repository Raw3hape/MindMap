//
//  MinimalRecordingView.swift
//  MindMap - Минималистичная версия
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct MinimalRecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedInputMethod: InputMethod = .voice
    
    enum InputMethod: CaseIterable {
        case voice, text
        
        var title: String {
            switch self {
            case .voice: return "Голос"
            case .text: return "Текст"
            }
        }
        
        var icon: String {
            switch self {
            case .voice: return "mic"
            case .text: return "text.cursor"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.minimalBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Простой заголовок
                    headerSection
                    
                    Spacer()
                    
                    // Переключатель метода ввода
                    inputMethodSelector
                    
                    Spacer()
                    
                    // Основная область ввода
                    if selectedInputMethod == .voice {
                        voiceInputSection
                    } else {
                        textInputSection
                    }
                    
                    Spacer()
                    
                    // Кнопка создания задачи
                    createTaskButton
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }
            .navigationBarHidden(true)
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Произошла неизвестная ошибка")
        }
        .onChange(of: viewModel.isProcessing) { _, isProcessing in
            if !isProcessing && !viewModel.showError {
                dismiss()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button("Отмена") {
                dismiss()
            }
            .font(.system(size: 17))
            .foregroundColor(.minimalTextSecondary)
            
            Spacer()
            
            Text("Новая задача")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.minimalTextPrimary)
            
            Spacer()
            
            // Пустое место для симметрии
            Color.clear
                .frame(width: 60)
        }
    }
    
    // MARK: - Input Method Selector
    private var inputMethodSelector: some View {
        HStack(spacing: 0) {
            ForEach(InputMethod.allCases, id: \.self) { method in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedInputMethod = method
                        // Сбрасываем данные при переключении
                        if method == .voice {
                            viewModel.manualText = ""
                        } else {
                            viewModel.clearRecording()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: method.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(method.title)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(selectedInputMethod == method ? .white : .minimalTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        selectedInputMethod == method ? 
                        Color.minimalAccent : Color.clear
                    )
                }
            }
        }
        .background(Color.minimalSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.minimalBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Voice Input Section
    private var voiceInputSection: some View {
        VStack(spacing: 32) {
            // Большая кнопка записи
            MinimalRecordButton(
                isRecording: viewModel.isRecording,
                action: viewModel.toggleRecording
            )
            
            // Простая информация о записи
            if viewModel.isRecording {
                Text("Говорите...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.minimalTextSecondary)
                    .opacity(0.8)
            } else if viewModel.hasRecording {
                VStack(spacing: 12) {
                    Text(viewModel.formatDuration(viewModel.recordingDuration))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.minimalTextPrimary)
                    
                    HStack(spacing: 24) {
                        Button("Прослушать") {
                            viewModel.playRecording()
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.minimalAccent)
                        
                        Button("Удалить") {
                            viewModel.clearRecording()
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.error)
                    }
                }
            } else {
                Text("Нажмите чтобы записать")
                    .font(.system(size: 18))
                    .foregroundColor(.minimalTextSecondary)
            }
        }
    }
    
    // MARK: - Text Input Section
    private var textInputSection: some View {
        VStack(spacing: 16) {
            MinimalTextField(
                placeholder: "Опишите вашу задачу подробно...",
                text: $viewModel.manualText,
                maxHeight: 200
            )
            
            if viewModel.hasManualText {
                HStack {
                    Spacer()
                    Text("\(viewModel.manualText.count) символов")
                        .font(.system(size: 14))
                        .foregroundColor(.minimalTextSecondary)
                }
            }
        }
    }
    
    // MARK: - Create Task Button
    private var createTaskButton: some View {
        MinimalActionButton(
            title: viewModel.isProcessing ? "Создаем..." : "Создать задачу",
            icon: viewModel.isProcessing ? nil : "plus",
            isLoading: viewModel.isProcessing,
            action: processTask
        )
        .disabled(!viewModel.canProcess)
        .opacity(viewModel.canProcess ? 1.0 : 0.5)
    }
    
    // MARK: - Actions
    private func processTask() {
        _Concurrency.Task { @MainActor in
            if selectedInputMethod == .voice && viewModel.hasRecording {
                await viewModel.processRecording()
            } else if selectedInputMethod == .text && viewModel.hasManualText {
                await viewModel.processManualText()
            }
        }
    }
}

#Preview {
    MinimalRecordingView()
}

#Preview("Dark Mode") {
    MinimalRecordingView()
        .preferredColorScheme(.dark)
}