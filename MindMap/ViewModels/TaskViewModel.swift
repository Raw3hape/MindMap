//
//  TaskViewModel.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Task View Model
@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var completedTasks: [Task] = []
    @Published var searchText = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var showCompleted = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        setupCoreDataObserver()
        // Загружаем данные асинхронно, не блокируя UI
        loadTasks()
    }
    
    private func setupBindings() {
        // Обновляем список при изменении поискового запроса или фильтра
        Publishers.CombineLatest($searchText, $selectedFilter)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.filterTasks()
            }
            .store(in: &cancellables)
    }
    
    private func setupCoreDataObserver() {
        // Подписываемся на уведомления об изменениях в Core Data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("🔄 Core Data изменился, перезагружаем задачи")
                self?.loadTasks()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadTasks() {
        _Concurrency.Task { @MainActor in
            isLoading = true
            
            let allTasks = await _Concurrency.Task.detached { [coreDataManager] in
                return await coreDataManager.fetchTasks()
            }.value
            
            let completed = await _Concurrency.Task.detached { [coreDataManager] in
                return await coreDataManager.fetchCompletedTasks()
            }.value
            
            tasks = allTasks
            completedTasks = completed
            isLoading = false
            filterTasks()
        }
    }
    
    func refreshTasks() {
        loadTasks()
    }
    
    // MARK: - Task Operations
    func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.completedAt = updatedTask.isCompleted ? Date() : nil
        
        coreDataManager.updateTask(updatedTask)
        updateLocalTask(updatedTask)
    }
    
    func deleteTask(_ task: Task) {
        coreDataManager.deleteTask(task)
        removeLocalTask(task)
    }
    
    func updateTask(_ task: Task) {
        coreDataManager.updateTask(task)
        updateLocalTask(task)
    }
    
    func toggleSubtaskCompletion(_ subtask: Subtask, in task: Task) {
        coreDataManager.toggleSubtaskCompletion(subtask, in: task)
        
        // Обновляем локальную копию
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            if let subtaskIndex = tasks[index].subtasks.firstIndex(where: { $0.id == subtask.id }) {
                tasks[index].subtasks[subtaskIndex].isCompleted.toggle()
                tasks[index].subtasks[subtaskIndex].completedAt = tasks[index].subtasks[subtaskIndex].isCompleted ? Date() : nil
            }
        }
    }
    
    // MARK: - Filtering and Search
    private func filterTasks() {
        var filteredTasks = showCompleted ? completedTasks : tasks.filter { !$0.isCompleted }
        
        // Применяем поиск
        if !searchText.isEmpty {
            filteredTasks = filteredTasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description?.localizedCaseInsensitiveContains(searchText) == true ||
                task.originalText?.localizedCaseInsensitiveContains(searchText) == true ||
                task.subtasks.contains { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Применяем фильтр по приоритету
        switch selectedFilter {
        case .all:
            break
        case .high:
            filteredTasks = filteredTasks.filter { $0.priority == .high }
        case .medium:
            filteredTasks = filteredTasks.filter { $0.priority == .medium }
        case .low:
            filteredTasks = filteredTasks.filter { $0.priority == .low }
        }
        
        // Обновляем отображаемые задачи
        tasks = showCompleted ? filteredTasks : filteredTasks
    }
    
    // MARK: - Local Updates
    private func updateLocalTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
        }
        
        if let index = completedTasks.firstIndex(where: { $0.id == updatedTask.id }) {
            completedTasks[index] = updatedTask
        }
        
        filterTasks()
    }
    
    private func removeLocalTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        completedTasks.removeAll { $0.id == task.id }
        filterTasks()
    }
    
    // MARK: - Statistics
    var totalTasks: Int {
        tasks.count + completedTasks.count
    }
    
    var completedTasksCount: Int {
        completedTasks.count
    }
    
    var pendingTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    var completionPercentage: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasks) * 100
    }
    
    // MARK: - Error Handling
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Task Filter Enum
enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "Все"
        case .high: return "Высокий"
        case .medium: return "Средний"
        case .low: return "Низкий"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .high: return "exclamationmark.3"
        case .medium: return "exclamationmark.2"
        case .low: return "exclamationmark"
        }
    }
}