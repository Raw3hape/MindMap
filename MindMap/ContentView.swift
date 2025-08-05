//
//  ContentView.swift
//  MindMap - Минималистичная версия
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Фон
            Color.minimalBackground
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Главный экран с задачами
                TaskListView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "list.bullet" : "list.bullet")
                        Text("Задачи")
                    }
                    .tag(0)
                
                // Экран записи
                MinimalRecordingView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "plus.circle.fill" : "plus.circle")
                        Text("Создать")
                    }
                    .tag(1)
                
                // Экран настроек
                MinimalSettingsView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                        Text("Настройки")
                    }
                    .tag(2)
            }
            .accentColor(.minimalAccent)
            .preferredColorScheme(getColorScheme())
            .environmentObject(themeManager)
            .onAppear {
                // Настройка внешнего вида таб-бара
                configureTabBar()
                logInfo("🏠 ContentView появился, текущая тема: \(themeManager.currentTheme.displayName)", category: .ui)
            }
            .onChange(of: themeManager.currentTheme) { _, newTheme in
                configureTabBar()
                logInfo("🔄 ContentView: тема изменена на \(newTheme.displayName)", category: .ui)
            }
        }
    }
    
    private func getColorScheme() -> ColorScheme? {
        switch themeManager.currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Позволяет системе определить тему
        }
    }
    
    private func configureTabBar() {
        // Настройка внешнего вида таб-бара для минималистичного дизайна
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Используем реальную тему из ThemeManager, а не системную
        let isDarkTheme = themeManager.isDarkMode
        
        if isDarkTheme {
            // Темная тема
            appearance.backgroundColor = UIColor(MinimalColors.Dark.surface)
            appearance.shadowColor = UIColor(MinimalColors.Dark.border)
            
            // Цвета элементов в темной теме
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(MinimalColors.Dark.textSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(MinimalColors.Dark.textSecondary)
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(MinimalColors.Dark.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(MinimalColors.Dark.accent)
            ]
        } else {
            // Светлая тема
            appearance.backgroundColor = UIColor(MinimalColors.surface)
            appearance.shadowColor = UIColor(MinimalColors.border)
            
            // Цвета элементов в светлой теме
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(MinimalColors.textSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(MinimalColors.textSecondary)
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(MinimalColors.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(MinimalColors.accent)
            ]
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Принудительно обновляем все TabBar
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                for view in window.subviews {
                    view.removeFromSuperview()
                    window.addSubview(view)
                }
            }
        }
    }
}

// Старые компоненты удалены - теперь используются минималистичные версии

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
}