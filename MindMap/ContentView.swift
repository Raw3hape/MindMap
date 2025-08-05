//
//  ContentView.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Главный экран с задачами
            TaskListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Задачи")
                }
                .tag(0)
            
            // Экран записи
            RecordingView()
                .tabItem {
                    Image(systemName: "mic.circle")
                    Text("Запись")
                }
                .tag(1)
            
            // Экран настроек
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Настройки")
                }
                .tag(2)
        }
        .accentColor(AppColors.primary)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .environmentObject(themeManager)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Внешний вид") {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)
                        
                        Text("Тема")
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Picker("Тема", selection: $themeManager.currentTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                HStack {
                                    Image(systemName: theme.icon)
                                    Text(theme.displayName)
                                }
                                .tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Приложение") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppColors.info)
                            .frame(width: 24)
                        
                        Text("О приложении")
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .onTapGesture {
                        showingAbout = true
                    }
                    
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(AppColors.warning)
                            .frame(width: 24)
                        
                        Text("Помощь")
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Section("Данные") {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.error)
                            .frame(width: 24)
                        
                        Text("Очистить все данные")
                            .foregroundColor(AppColors.error)
                    }
                }
            }
            .navigationTitle("Настройки")
            .listStyle(InsetGroupedListStyle())
            .themedBackground()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Лого и название
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primary)
                    
                    Text("MindMap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.text)
                    
                    Text("Версия 1.0")
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Описание
                VStack(spacing: 16) {
                    Text("Интеллектуальное приложение для создания и организации задач с помощью голосовых команд и ИИ.")
                        .font(.body)
                        .foregroundColor(AppColors.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Создано с использованием SwiftUI и OpenAI")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Контактная информация
                VStack(spacing: 8) {
                    Text("© 2025 MindMap")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("Разработано Nikita Sergyshkin")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding()
            .navigationTitle("О приложении")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .themedBackground()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
}