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
        // Загружаем сохраненную тему
        if let savedTheme = UserDefaults.standard.object(forKey: "AppTheme") as? String,
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
        
        updateTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "AppTheme")
        updateTheme()
    }
    
    private func updateTheme() {
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
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
    
    var icon: String {
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