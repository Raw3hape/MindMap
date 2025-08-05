//
//  MinimalTaskDetailView.swift
//  MindMap - Минималистичная версия
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct MinimalTaskDetailView: View {
    let task: Task
    let onUpdate: (Task) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editedTask: Task
    
    init(task: Task, onUpdate: @escaping (Task) -> Void) {
        self.task = task
        self.onUpdate = onUpdate
        self._editedTask = State(initialValue: task)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.minimalBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Заголовок
                        titleSection
                        
                        // Описание (если есть)
                        if let description = editedTask.description,
                           !description.isEmpty {
                            descriptionSection(description)
                        }
                        
                        // Подзадачи (если есть)
                        if !editedTask.subtasks.isEmpty {
                            subtasksSection
                        }
                        
                        // Приоритет
                        prioritySection
                        
                        // Кнопки действий
                        actionButtons
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                }
            }
            .navigationBarHidden(true)
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
            
            Text("Детали")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.minimalTextPrimary)
            
            Spacer()
            
            Button("Сохранить") {
                onUpdate(editedTask)
                dismiss()
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(.minimalAccent)
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .font(.system(size: 17))
                .foregroundColor(.minimalTextSecondary)
                
                Spacer()
                
                Button("Сохранить") {
                    onUpdate(editedTask)
                    dismiss()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.minimalAccent)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Название")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.minimalTextSecondary)
                
                MinimalTextField(
                    placeholder: "Введите название задачи...",
                    text: $editedTask.title
                )
            }
        }
    }
    
    // MARK: - Description Section
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Описание")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.minimalTextSecondary)
            
            Text(description)
                .font(.system(size: 17))
                .foregroundColor(.minimalTextPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.minimalSurface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.minimalBorder, lineWidth: 1)
                )
        }
    }
    
    // MARK: - Subtasks Section
    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Подзадачи")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.minimalTextSecondary)
            
            VStack(spacing: 12) {
                ForEach(Array(editedTask.subtasks.enumerated()), id: \.element.id) { index, subtask in
                    MinimalSubtaskRow(
                        subtask: subtask,
                        onToggle: { toggleSubtask(subtask) }
                    )
                }
            }
        }
    }
    
    // MARK: - Priority Section
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Приоритет")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.minimalTextSecondary)
            
            HStack(spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    Button(action: {
                        editedTask.priority = priority
                    }) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForPriority(priority))
                                .frame(width: 12, height: 12)
                            
                            Text(priority.displayName)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(editedTask.priority == priority ? .white : .minimalTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            editedTask.priority == priority ? 
                            colorForPriority(priority) : Color.minimalSurface
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    editedTask.priority == priority ? 
                                    Color.clear : Color.minimalBorder, 
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            MinimalActionButton(
                title: editedTask.isCompleted ? "Пометить как активную" : "Отметить выполненной",
                icon: editedTask.isCompleted ? "arrow.clockwise" : "checkmark",
                style: editedTask.isCompleted ? .secondary : .primary
            ) {
                editedTask.isCompleted.toggle()
                editedTask.completedAt = editedTask.isCompleted ? Date() : nil
            }
            
            MinimalActionButton(
                title: "Удалить задачу",
                icon: "trash",
                style: .destructive
            ) {
                // TODO: Добавить подтверждение удаления
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleSubtask(_ subtask: Subtask) {
        if let index = editedTask.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            editedTask.subtasks[index].isCompleted.toggle()
            editedTask.subtasks[index].completedAt = editedTask.subtasks[index].isCompleted ? Date() : nil
        }
    }
    
    private func colorForPriority(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .minimalTextSecondary
        case .medium: return Color.warning
        case .high: return Color.error
        }
    }
}

// MARK: - Minimal Subtask Row
struct MinimalSubtaskRow: View {
    let subtask: Subtask
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Чекбокс
                Circle()
                    .strokeBorder(
                        subtask.isCompleted ? Color.minimalAccent : Color.minimalBorder,
                        lineWidth: 2
                    )
                    .background(
                        Circle()
                            .fill(subtask.isCompleted ? Color.minimalAccent : Color.clear)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(subtask.isCompleted ? 1 : 0)
                    )
                    .frame(width: 20, height: 20)
                
                // Текст подзадачи
                Text(subtask.title)
                    .font(.system(size: 17))
                    .foregroundColor(.minimalTextPrimary)
                    .strikethrough(subtask.isCompleted)
                    .opacity(subtask.isCompleted ? 0.6 : 1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.minimalSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.minimalBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let sampleTask = Task(
        title: "Подготовиться к презентации",
        description: "Создать слайды и подготовить демонстрацию нового продукта для встречи с клиентами",
        priority: .high,
        subtasks: [
            Subtask(title: "Создать структуру презентации"),
            Subtask(title: "Подготовить демо", isCompleted: true),
            Subtask(title: "Отрепетировать выступление")
        ]
    )
    
    MinimalTaskDetailView(task: sampleTask) { _ in }
}

#Preview("Dark Mode") {
    let sampleTask = Task(
        title: "Изучить SwiftUI",
        description: "Пройти курс по разработке iOS приложений",
        priority: .medium
    )
    
    MinimalTaskDetailView(task: sampleTask) { _ in }
        .preferredColorScheme(.dark)
}