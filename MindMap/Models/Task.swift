//
//  Task.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation
import CoreData

// MARK: - Task Model
struct Task: Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    var isCompleted: Bool
    var priority: TaskPriority
    var createdAt: Date
    var completedAt: Date?
    var audioFilePath: String?
    var originalText: String?
    var subtasks: [Subtask]
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        audioFilePath: String? = nil,
        originalText: String? = nil,
        subtasks: [Subtask] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.audioFilePath = audioFilePath
        self.originalText = originalText
        self.subtasks = subtasks
    }
}

// MARK: - Subtask Model
struct Subtask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

// MARK: - Task Priority Enum
enum TaskPriority: Int16, CaseIterable, Identifiable {
    case low = 1
    case medium = 2
    case high = 3
    
    var id: Int16 { rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Низкий"
        case .medium: return "Средний"
        case .high: return "Высокий"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Core Data Extensions
extension TaskEntity {
    func toTask() -> Task {
        Task(
            id: self.id ?? UUID(),
            title: self.title ?? "",
            description: self.taskDescription,
            isCompleted: self.isCompleted,
            priority: TaskPriority(rawValue: self.priority) ?? .medium,
            createdAt: self.createdAt ?? Date(),
            completedAt: self.completedAt,
            audioFilePath: self.audioFilePath,
            originalText: self.originalText,
            subtasks: (self.subtasks?.allObjects as? [SubtaskEntity])?.map { $0.toSubtask() } ?? []
        )
    }
    
    func update(from task: Task, context: NSManagedObjectContext) {
        self.id = task.id
        self.title = task.title
        self.taskDescription = task.description
        self.isCompleted = task.isCompleted
        self.priority = task.priority.rawValue
        self.createdAt = task.createdAt
        self.completedAt = task.completedAt
        self.audioFilePath = task.audioFilePath
        self.originalText = task.originalText
        
        // Обновление подзадач
        let existingSubtasks = self.subtasks?.allObjects as? [SubtaskEntity] ?? []
        
        // Удаляем существующие подзадачи, которых нет в новом списке
        for existing in existingSubtasks {
            if !task.subtasks.contains(where: { $0.id == existing.id }) {
                context.delete(existing)
            }
        }
        
        // Добавляем или обновляем подзадачи
        for subtask in task.subtasks {
            if let existing = existingSubtasks.first(where: { $0.id == subtask.id }) {
                existing.update(from: subtask)
            } else {
                let newSubtask = SubtaskEntity(context: context)
                newSubtask.update(from: subtask)
                newSubtask.parentTask = self
            }
        }
    }
}

extension SubtaskEntity {
    func toSubtask() -> Subtask {
        Subtask(
            id: self.id ?? UUID(),
            title: self.title ?? "",
            isCompleted: self.isCompleted,
            createdAt: self.createdAt ?? Date(),
            completedAt: self.completedAt
        )
    }
    
    func update(from subtask: Subtask) {
        self.id = subtask.id
        self.title = subtask.title
        self.isCompleted = subtask.isCompleted
        self.createdAt = subtask.createdAt
        self.completedAt = subtask.completedAt
    }
}