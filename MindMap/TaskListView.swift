//
//  TaskListView.swift
//  MindMap - Минималистичная версия
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingRecordingView = false
    @State private var selectedTask: Task?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.minimalBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Простой заголовок с количеством
                    MinimalSectionHeader(
                        title: viewModel.showCompleted ? "Выполнено" : "Задачи",
                        count: filteredTasks.count
                    )
                    .padding(.top, 8)
                    
                    // Основной контент
                    if viewModel.isLoading {
                        loadingView
                    } else if filteredTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListSection
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRecordingView) {
            MinimalRecordingView()
        }
        .sheet(item: $selectedTask) { task in
            MinimalTaskDetailView(task: task) { updatedTask in
                viewModel.updateTask(updatedTask)
            }
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Произошла неизвестная ошибка")
        }
        .onAppear {
            if viewModel.tasks.isEmpty && viewModel.completedTasks.isEmpty {
                viewModel.loadTasks()
            }
        }
        .overlay(
            // Плавающие кнопки внизу экрана
            VStack {
                Spacer()
                floatingButtons
            }
            .ignoresSafeArea(.keyboard)
        )
    }
    
    // MARK: - Computed Properties
    private var filteredTasks: [Task] {
        let baseTasks = viewModel.showCompleted ? viewModel.completedTasks : viewModel.tasks.filter { !$0.isCompleted }
        
        // Простая фильтрация по тексту поиска (если добавим позже)
        if viewModel.searchText.isEmpty {
            return baseTasks
        } else {
            return baseTasks.filter { task in
                task.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
                (task.description?.localizedCaseInsensitiveContains(viewModel.searchText) ?? false)
            }
        }
    }
    
    // MARK: - Task List Section
    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTasks) { task in
                    MinimalTaskCard(
                        task: task,
                        onToggle: { viewModel.toggleTaskCompletion(task) },
                        onTap: { selectedTask = task }
                    )
                }
                
                // Отступ снизу для плавающих кнопок
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.minimalBackground)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .minimalAccent))
            
            Text("Загружаем...")
                .font(.system(size: 17))
                .foregroundColor(.minimalTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        MinimalEmptyState(
            icon: viewModel.showCompleted ? "checkmark.circle" : "list.clipboard",
            title: viewModel.showCompleted ? "Пока пусто" : "Начнем?",
            subtitle: viewModel.showCompleted ? 
                "Выполненные задачи появятся здесь" : 
                "Создайте первую задачу голосом или текстом",
            buttonTitle: viewModel.showCompleted ? nil : "Создать задачу",
            buttonAction: viewModel.showCompleted ? nil : { showingRecordingView = true }
        )
    }
    
    // MARK: - Floating Buttons
    private var floatingButtons: some View {
        HStack(spacing: 16) {
            // Переключатель активные/выполненные
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.showCompleted.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.showCompleted ? "list.bullet" : "checkmark.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text(viewModel.showCompleted ? "Активные" : "Готово")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.minimalTextPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(25)
            }
            
            Spacer()
            
            // Кнопка создания задачи
            Button(action: { showingRecordingView = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.minimalAccent)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

#Preview {
    TaskListView()
}

#Preview("Dark Mode") {
    TaskListView()
        .preferredColorScheme(.dark)
}