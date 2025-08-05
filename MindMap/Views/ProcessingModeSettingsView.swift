//
//  ProcessingModeSettingsView.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct ProcessingModeSettingsView: View {
    @ObservedObject var openAIService = OpenAIService.shared
    @ObservedObject var speechService = SpeechRecognitionService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Выберите как приложение будет обрабатывать голосовые записи:")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                } header: {
                    Text("Режим обработки речи")
                }
                
                ForEach(ProcessingMode.allCases, id: \.self) { mode in
                    ProcessingModeRow(
                        mode: mode,
                        isSelected: openAIService.processingMode == mode,
                        isRecommended: mode == .speechOnly
                    ) {
                        openAIService.setProcessingMode(mode)
                    }
                }
                
                Section {
                    Toggle("Приоритет офлайн режима", isOn: $openAIService.useOfflineFirst)
                        .onChange(of: openAIService.useOfflineFirst) { _, newValue in
                            openAIService.setOfflineFirst(newValue)
                        }
                    
                    Text("Когда включено, приложение будет стараться использовать локальное распознавание речи iOS вместо облачных сервисов.")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                } header: {
                    Text("Настройки")
                }
                
                Section {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(speechService.isSpeechRecognitionAvailable ? AppColors.success : AppColors.error)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iOS Speech Framework")
                                .font(.body)
                            
                            Text(speechService.isSpeechRecognitionAvailable ? "Доступен" : "Недоступен")
                                .font(.caption)
                                .foregroundColor(speechService.isSpeechRecognitionAvailable ? AppColors.success : AppColors.error)
                        }
                        
                        Spacer()
                        
                        if speechService.isOnDeviceRecognitionAvailable {
                            VStack(alignment: .trailing, spacing: 2) {
                                Image(systemName: "wifi.slash")
                                    .font(.caption)
                                    .foregroundColor(AppColors.primary)
                                
                                Text("Офлайн")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "cloud")
                            .foregroundColor(AppColors.info)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OpenAI Whisper")
                                .font(.body)
                            
                            Text("Высокая точность • Требует интернет")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Image(systemName: "wifi")
                                .font(.caption)
                                .foregroundColor(AppColors.info)
                            
                            Text("Онлайн")
                                .font(.caption2)
                                .foregroundColor(AppColors.info)
                        }
                    }
                } header: {
                    Text("Доступные технологии")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(AppColors.warning)
                            Text("Рекомендации")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            RecommendationRow(
                                icon: "speedometer",
                                title: "Для быстрой работы",
                                description: "Выберите \"Только iOS\"",
                                color: AppColors.success
                            )
                            
                            RecommendationRow(
                                icon: "star",
                                title: "Рекомендуется",
                                description: "iOS Speech + GPT анализ",
                                color: AppColors.primary
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Справка")
                }
            }
            .navigationTitle("Обработка речи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProcessingModeRow: View {
    let mode: ProcessingMode
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.displayName)
                            .font(.body)
                            .foregroundColor(AppColors.text)
                        
                        if isRecommended {
                            Text("Рекомендуется")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.primary.opacity(0.1))
                                .foregroundColor(AppColors.primary)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.text)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    ProcessingModeSettingsView()
}