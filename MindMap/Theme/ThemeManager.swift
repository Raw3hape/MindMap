//
//  ThemeManager.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI
import Combine

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var isDarkMode: Bool = false
    
    private init() {
        logInfo("🎨 Инициализация ThemeManager", category: .ui)
        
        // Загружаем сохраненную тему
        if let savedTheme = UserDefaults.standard.object(forKey: "AppTheme") as? String,
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
            logInfo("📖 Загружена сохраненная тема: \(theme.displayName)", category: .ui)
        } else {
            logInfo("🆕 Используется тема по умолчанию: \(currentTheme.displayName)", category: .ui)
        }
        
        updateTheme()
        
        // Отслеживаем изменения системной темы
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    func setTheme(_ theme: AppTheme) {
        logInfo("🔄 Переключение темы на: \(theme.displayName)", category: .ui)
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "AppTheme")
        updateTheme()
    }
    
    private func updateTheme() {
        let previousMode = isDarkMode
        
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        logInfo("✨ Тема обновлена: \(currentTheme.displayName) -> isDarkMode: \(isDarkMode)", category: .ui)
        
        if previousMode != isDarkMode {
            logInfo("🎨 Режим изменен с \(previousMode ? "темного" : "светлого") на \(isDarkMode ? "темный" : "светлый")", category: .ui)
        }
    }
    
    @objc private func systemThemeChanged() {
        if currentTheme == .system {
            logInfo("🔄 Обновление системной темы", category: .ui)
            updateTheme()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - App Theme Enum
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Светлая"
        case .dark: return "Темная"
        case .system: return "Системная"
        }
    }
    
    var themeIcon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "gear"
        }
    }
}

// MARK: - View Extension for Theme
extension View {
    func themedBackground() -> some View {
        self.background(AppColors.background)
    }
    
    func themedForeground() -> some View {
        self.foregroundColor(AppColors.text)
    }
}