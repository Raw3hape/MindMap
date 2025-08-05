//
//  CoreDataManager.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import CoreData
import Foundation

// MARK: - Core Data Manager
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MindMap")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data ошибка: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения: \(error)")
            }
        }
    }
    
    // MARK: - Task Operations
    func createTask(_ task: Task) {
        let taskEntity = TaskEntity(context: context)
        taskEntity.update(from: task, context: context)
        save()
    }
    
    func updateTask(_ task: Task) {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let taskEntity = results.first {
                taskEntity.update(from: task, context: context)
                save()
            }
        } catch {
            print("Ошибка обновления задачи: \(error)")
        }
    }
    
    func deleteTask(_ task: Task) {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let taskEntity = results.first {
                context.delete(taskEntity)
                save()
            }
        } catch {
            print("Ошибка удаления задачи: \(error)")
        }
    }
    
    func fetchTasks() -> [Task] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.priority, ascending: false),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
        ]
        
        do {
            let taskEntities = try context.fetch(request)
            return taskEntities.map { $0.toTask() }
        } catch {
            print("Ошибка загрузки задач: \(error)")
            return []
        }
    }
    
    func fetchCompletedTasks() -> [Task] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.completedAt, ascending: false)]
        
        do {
            let taskEntities = try context.fetch(request)
            return taskEntities.map { $0.toTask() }
        } catch {
            print("Ошибка загрузки выполненных задач: \(error)")
            return []
        }
    }
    
    func fetchPendingTasks() -> [Task] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.priority, ascending: false),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
        ]
        
        do {
            let taskEntities = try context.fetch(request)
            return taskEntities.map { $0.toTask() }
        } catch {
            print("Ошибка загрузки активных задач: \(error)")
            return []
        }
    }
    
    // MARK: - Subtask Operations
    func toggleSubtaskCompletion(_ subtask: Subtask, in task: Task) {
        var updatedTask = task
        if let index = updatedTask.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            updatedTask.subtasks[index].isCompleted.toggle()
            updatedTask.subtasks[index].completedAt = updatedTask.subtasks[index].isCompleted ? Date() : nil
            updateTask(updatedTask)
        }
    }
    
    // MARK: - Search
    func searchTasks(query: String) -> [Task] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "title CONTAINS[cd] %@ OR taskDescription CONTAINS[cd] %@ OR originalText CONTAINS[cd] %@",
            query, query, query
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]
        
        do {
            let taskEntities = try context.fetch(request)
            return taskEntities.map { $0.toTask() }
        } catch {
            print("Ошибка поиска задач: \(error)")
            return []
        }
    }
}

// MARK: - Preview Helper
@MainActor
extension CoreDataManager {
    static let preview: CoreDataManager = {
        let manager = CoreDataManager()
        let context = manager.context
        
        // Создаем тестовые данные
        let sampleTasks = [
            Task(title: "Купить продукты", description: "Молоко, хлеб, яйца", priority: .medium),
            Task(title: "Встреча с командой", description: "Обсудить новый проект", priority: .high),
            Task(title: "Прочитать книгу", description: "Закончить главу 5", priority: .low, subtasks: [
                Subtask(title: "Прочитать страницы 100-120"),
                Subtask(title: "Сделать заметки")
            ])
        ]
        
        for task in sampleTasks {
            manager.createTask(task)
        }
        
        return manager
    }()
}