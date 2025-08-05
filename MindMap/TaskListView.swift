//
//  TaskListView.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingRecordingView = false
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Поиск и фильтры
                    searchAndFilterSection
                    
                    // Статистика
                    if !viewModel.tasks.isEmpty || !viewModel.completedTasks.isEmpty {
                        statisticsSection
                    }
                    
                    // Список задач
                    if viewModel.isLoading {
                        loadingView
                    } else if filteredTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListSection
                    }
                }
            }
            .navigationTitle("Задачи")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingRecordingView = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.showCompleted.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.showCompleted ? "checkmark.circle.fill" : "list.bullet")
                            Text(viewModel.showCompleted ? "Активные" : "Выполненные")
                        }
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
            .refreshable {
                viewModel.refreshTasks()
            }
        }
        .sheet(isPresented: $showingRecordingView) {
            RecordingView()
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task) { updatedTask in
                viewModel.updateTask(updatedTask)
            }
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Произошла неизвестная ошибка")
        }
        .onAppear {
            viewModel.loadTasks()
        }
    }
    
    // MARK: - Computed Properties
    private var filteredTasks: [Task] {
        viewModel.showCompleted ? viewModel.completedTasks : viewModel.tasks.filter { !$0.isCompleted }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Поисковая строка
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Поиск задач...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(AppColors.text)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surface)
            .cornerRadius(12)
            
            // Фильтры по приоритету
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TaskFilter.allCases) { filter in
                        FilterChip(
                            title: filter.displayName,
                            icon: filter.icon,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        HStack(spacing: 20) {
            StatisticCard(
                title: "Всего",
                value: "\(viewModel.totalTasks)",
                icon: "list.bullet",
                color: AppColors.info
            )
            
            StatisticCard(
                title: "Выполнено",
                value: "\(viewModel.completedTasksCount)",
                icon: "checkmark.circle",
                color: AppColors.success
            )
            
            StatisticCard(
                title: "Активных",
                value: "\(viewModel.pendingTasksCount)",
                icon: "clock",
                color: AppColors.warning
            )
            
            StatisticCard(
                title: "Прогресс",
                value: "\(Int(viewModel.completionPercentage))%",
                icon: "chart.line.uptrend.xyaxis",
                color: AppColors.primary
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Task List Section
    private var taskListSection: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskRowView(
                    task: task,
                    onToggleCompletion: { viewModel.toggleTaskCompletion(task) },
                    onToggleSubtask: { subtask in
                        viewModel.toggleSubtaskCompletion(subtask, in: task)
                    },
                    onTap: { selectedTask = task }
                )
                .listRowBackground(AppColors.surface)
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteTasks)
        }
        .listStyle(PlainListStyle())
        .background(AppColors.background)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
            
            Text("Загружаем задачи...")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.showCompleted ? "checkmark.circle" : "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text(viewModel.showCompleted ? "Нет выполненных задач" : "Нет активных задач")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppColors.text)
            
            Text(viewModel.showCompleted ? 
                 "Выполненные задачи появятся здесь" : 
                 "Создайте первую задачу, нажав кнопку +")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if !viewModel.showCompleted {
                Button(action: { showingRecordingView = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Создать задачу")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(25)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Actions
    private func deleteTasks(offsets: IndexSet) {
        withAnimation(.easeOut(duration: 0.3)) {
            for index in offsets {
                let task = filteredTasks[index]
                viewModel.deleteTask(task)
            }
        }
    }
}

// MARK: - Filter Chip View
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : AppColors.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.primary : AppColors.surface)
                    .stroke(isSelected ? Color.clear : AppColors.border, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Statistic Card View
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.text)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Заголовок и описание
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Заголовок")
                            .font(.headline)
                            .foregroundColor(AppColors.text)
                        
                        TextField("Заголовок задачи", text: $editedTask.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if let description = editedTask.description {
                            Text("Описание")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(AppColors.textSecondary)
                                .padding()
                                .background(AppColors.surface)
                                .cornerRadius(8)
                        }
                    }
                    
                    // Подзадачи
                    if !editedTask.subtasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Подзадачи")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                            
                            ForEach(editedTask.subtasks) { subtask in
                                HStack {
                                    Button(action: { toggleSubtask(subtask) }) {
                                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(subtask.isCompleted ? AppColors.success : AppColors.textSecondary)
                                    }
                                    
                                    Text(subtask.title)
                                        .font(.body)
                                        .foregroundColor(AppColors.text)
                                        .strikethrough(subtask.isCompleted)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Приоритет
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Приоритет")
                            .font(.headline)
                            .foregroundColor(AppColors.text)
                        
                        Picker("Приоритет", selection: $editedTask.priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Детали задачи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        onUpdate(editedTask)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleSubtask(_ subtask: Subtask) {
        if let index = editedTask.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            editedTask.subtasks[index].isCompleted.toggle()
            editedTask.subtasks[index].completedAt = editedTask.subtasks[index].isCompleted ? Date() : nil
        }
    }
}

#Preview {
    TaskListView()
}

#Preview("Dark Mode") {
    TaskListView()
        .preferredColorScheme(.dark)
}