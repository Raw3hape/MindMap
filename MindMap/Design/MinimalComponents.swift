//
//  MinimalComponents.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

// MARK: - Минималистичная карточка задачи
struct MinimalTaskCard: View {
    let task: Task
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Большой чекбокс (44pt для лучшего тач-таргета)
                Button(action: onToggle) {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Color.minimalAccent : Color.minimalBorder,
                            lineWidth: 2
                        )
                        .background(
                            Circle()
                                .fill(task.isCompleted ? Color.minimalAccent : Color.clear)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .opacity(task.isCompleted ? 1 : 0)
                        )
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Содержимое задачи
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.minimalTextPrimary)
                        .multilineTextAlignment(.leading)
                        .strikethrough(task.isCompleted)
                        .opacity(task.isCompleted ? 0.6 : 1.0)
                    
                    // Показываем описание только если оно есть и не слишком длинное
                    if let description = task.description,
                       !description.isEmpty,
                       description.count < 100 {
                        Text(description)
                            .font(.system(size: 15))
                            .foregroundColor(.minimalTextSecondary)
                            .lineLimit(2)
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.5 : 1.0)
                    }
                    
                    // Простой индикатор приоритета - только для высокого приоритета
                    if task.priority == .high && !task.isCompleted {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.error)
                                .frame(width: 6, height: 6)
                            Text("Важно")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.error)
                        }
                    }
                    
                    // Количество подзадач (только если есть)
                    if !task.subtasks.isEmpty {
                        Text("\(completedSubtasks)/\(task.subtasks.count) подзадач")
                            .font(.system(size: 12))
                            .foregroundColor(.minimalTextSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color.minimalSurface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.minimalBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var completedSubtasks: Int {
        task.subtasks.filter { $0.isCompleted }.count
    }
}

// MARK: - Минималистичная кнопка записи
struct MinimalRecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Фон
                Circle()
                    .fill(isRecording ? Color.error : Color.minimalAccent)
                    .frame(width: 120, height: 120)
                
                // Иконка
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                
                // Анимированное кольцо при записи
                if isRecording {
                    Circle()
                        .strokeBorder(Color.error.opacity(0.3), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .scaleEffect(1.2)
                        .opacity(0.7)
                        .animation(
                            .easeInOut(duration: 1)
                            .repeatForever(autoreverses: true),
                            value: isRecording
                        )
                }
            }
        }
        .scaleEffect(isRecording ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isRecording)
    }
}

// MARK: - Минималистичная кнопка действия
struct MinimalActionButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .minimalAccent
            case .secondary: return .minimalSurface
            case .destructive: return .error
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .minimalTextPrimary
            case .destructive: return .white
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .primary: return nil
            case .secondary: return .minimalBorder
            case .destructive: return nil
            }
        }
    }
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundColor(style.textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(style.backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style.borderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }
}

// MARK: - Минималистичное текстовое поле
struct MinimalTextField: View {
    let placeholder: String
    @Binding var text: String
    let maxHeight: CGFloat?
    
    init(placeholder: String, text: Binding<String>, maxHeight: CGFloat? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.minimalSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.minimalBorder, lineWidth: 1)
                )
                .frame(minHeight: maxHeight ?? 120)
            
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 17))
                    .foregroundColor(.minimalTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
            
            if let maxHeight = maxHeight {
                TextEditor(text: $text)
                    .font(.system(size: 17))
                    .foregroundColor(.minimalTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: maxHeight)
            } else {
                TextField("", text: $text)
                    .font(.system(size: 17))
                    .foregroundColor(.minimalTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Минималистичный переключатель
struct MinimalToggle: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.minimalTextPrimary)
                
                if let description = description {
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(.minimalTextSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.minimalAccent)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.minimalSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.minimalBorder, lineWidth: 1)
        )
    }
}

// MARK: - Пустое состояние
struct MinimalEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.minimalTextSecondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.minimalTextPrimary)
                
                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(.minimalTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                MinimalActionButton(
                    title: buttonTitle,
                    icon: "plus",
                    action: buttonAction
                )
                .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Минималистичный заголовок секции
struct MinimalSectionHeader: View {
    let title: String
    let count: Int?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.minimalTextPrimary)
            
            if let count = count {
                Text("\(count)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.minimalTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.minimalSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.minimalBorder, lineWidth: 1)
                    )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}