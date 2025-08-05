//
//  TaskRowView.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onToggleCompletion: () -> Void
    let onToggleSubtask: (Subtask) -> Void
    let onTap: () -> Void
    
    @State private var showingSubtasks = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Основная часть задачи
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Чекбокс
                    Button(action: onToggleCompletion) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(task.isCompleted ? AppColors.success : AppColors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Содержание задачи
                    VStack(alignment: .leading, spacing: 8) {
                        // Заголовок и приоритет
                        HStack(alignment: .top) {
                            Text(task.title)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.text)
                                .strikethrough(task.isCompleted)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            // Индикатор приоритета
                            priorityIndicator
                        }
                        
                        // Описание
                        if let description = task.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(2)
                                .strikethrough(task.isCompleted)
                        }
                        
                        // Метаданные
                        taskMetadata
                    }
                    
                    // Индикатор наличия подзадач
                    if !task.subtasks.isEmpty {
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSubtasks.toggle()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: showingSubtasks ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text("\(completedSubtasksCount)/\(task.subtasks.count)")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Подзадачи (сворачиваемые)
            if showingSubtasks && !task.subtasks.isEmpty {
                subtasksSection
            }
        }
        .background(taskBackground)
        .cornerRadius(16)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Priority Indicator
    private var priorityIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            Text(task.priority.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(priorityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low:
            return AppColors.priorityLow
        case .medium:
            return AppColors.priorityMedium
        case .high:
            return AppColors.priorityHigh
        }
    }
    
    // MARK: - Task Metadata
    private var taskMetadata: some View {
        HStack(spacing: 16) {
            // Дата создания
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
                Text(task.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            // Аудио индикатор
            if task.audioFilePath != nil {
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(AppColors.info)
                    Text("Аудио")
                        .font(.caption)
                        .foregroundColor(AppColors.info)
                }
            }
            
            // Количество подзадач
            if !task.subtasks.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                    Text("\(task.subtasks.count)")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            // Статус выполнения
            if task.isCompleted, let completedAt = task.completedAt {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.success)
                    Text(completedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(AppColors.success)
                }
            }
        }
    }
    
    // MARK: - Subtasks Section
    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(AppColors.border)
                .padding(.horizontal, 16)
            
            ForEach(Array(task.subtasks.enumerated()), id: \.element.id) { index, subtask in
                SubtaskRowView(
                    subtask: subtask,
                    onToggle: { onToggleSubtask(subtask) }
                )
                
                if index < task.subtasks.count - 1 {
                    Divider()
                        .background(AppColors.border)
                        .padding(.leading, 56)
                }
            }
        }
        .transition(.slide.combined(with: .opacity))
    }
    
    // MARK: - Background
    private var taskBackground: Color {
        if task.isCompleted {
            return AppColors.taskCompleted
        } else {
            return AppColors.surface
        }
    }
    
    // MARK: - Computed Properties
    private var completedSubtasksCount: Int {
        task.subtasks.filter { $0.isCompleted }.count
    }
}

// MARK: - Subtask Row View
struct SubtaskRowView: View {
    let subtask: Subtask
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Отступ для визуального выделения подзадачи
                Rectangle()
                    .fill(AppColors.border)
                    .frame(width: 2, height: 20)
                    .padding(.leading, 24)
                
                // Чекбокс
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundColor(subtask.isCompleted ? AppColors.success : AppColors.textSecondary)
                
                // Текст подзадачи
                Text(subtask.title)
                    .font(.body)
                    .foregroundColor(AppColors.text)
                    .strikethrough(subtask.isCompleted)
                    .lineLimit(1)
                
                Spacer()
                
                // Время выполнения
                if subtask.isCompleted, let completedAt = subtask.completedAt {
                    Text(completedAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(AppColors.success)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AppColors.surface)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let sampleTask = Task(
        title: "Подготовиться к презентации",
        description: "Создать слайды и подготовить демонстрацию нового продукта",
        priority: .high,
        audioFilePath: "/path/to/audio.m4a",
        subtasks: [
            Subtask(title: "Создать структуру презентации"),
            Subtask(title: "Подготовить демо", isCompleted: true),
            Subtask(title: "Отрепетировать выступление")
        ]
    )
    
    return VStack {
        TaskRowView(
            task: sampleTask,
            onToggleCompletion: { },
            onToggleSubtask: { _ in },
            onTap: { }
        )
        .padding()
        
        Spacer()
    }
    .background(AppColors.background)
}

#Preview("Completed Task") {
    let completedTask = Task(
        title: "Купить продукты",
        description: "Молоко, хлеб, яйца",
        isCompleted: true,
        priority: .medium,
        completedAt: Date()
    )
    
    return VStack {
        TaskRowView(
            task: completedTask,
            onToggleCompletion: { },
            onToggleSubtask: { _ in },
            onTap: { }
        )
        .padding()
        
        Spacer()
    }
    .background(AppColors.background)
}