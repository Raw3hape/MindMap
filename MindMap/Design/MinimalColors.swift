//
//  MinimalColors.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

// MARK: - Минималистичная цветовая схема
struct MinimalColors {
    // Основные цвета - всего 3
    static let primary = Color(red: 0.13, green: 0.13, blue: 0.13)     // #212121 - темно-серый
    static let accent = Color(red: 0.2, green: 0.6, blue: 1.0)         // #3399FF - синий акцент
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98)  // #FAFAFA - очень светло-серый
    
    // Оттенки серого для текста
    static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13) // #212121
    static let textSecondary = Color(red: 0.46, green: 0.46, blue: 0.46) // #757575
    static let textTertiary = Color(red: 0.74, green: 0.74, blue: 0.74) // #BDBDBD
    
    // Системные цвета
    static let success = Color(red: 0.2, green: 0.7, blue: 0.3)        // #33B84A - зеленый
    static let error = Color(red: 0.96, green: 0.26, blue: 0.21)       // #F44336 - красный
    static let warning = Color(red: 1.0, green: 0.76, blue: 0.03)      // #FFC107 - желтый
    
    // Поверхности
    static let surface = Color.white
    static let surfaceSecondary = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5
    
    // Границы
    static let border = Color(red: 0.89, green: 0.89, blue: 0.89)      // #E3E3E3
    
    // Темная тема
    struct Dark {
        static let primary = Color.white
        static let accent = Color(red: 0.4, green: 0.7, blue: 1.0)     // Светлее для темной темы
        static let background = Color(red: 0.07, green: 0.07, blue: 0.07) // #121212
        
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.7, green: 0.7, blue: 0.7)
        static let textTertiary = Color(red: 0.5, green: 0.5, blue: 0.5)
        
        static let surface = Color(red: 0.12, green: 0.12, blue: 0.12)
        static let surfaceSecondary = Color(red: 0.16, green: 0.16, blue: 0.16)
        
        static let border = Color(red: 0.3, green: 0.3, blue: 0.3)
    }
}

// MARK: - Расширение Color для динамических цветов
extension Color {
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Минималистичные цвета для системы
extension Color {
    // Адаптивные цвета
    static let minimalPrimary = dynamicColor(
        light: MinimalColors.primary,
        dark: MinimalColors.Dark.primary
    )
    
    static let minimalAccent = dynamicColor(
        light: MinimalColors.accent,
        dark: MinimalColors.Dark.accent
    )
    
    static let minimalBackground = dynamicColor(
        light: MinimalColors.background,
        dark: MinimalColors.Dark.background
    )
    
    static let minimalTextPrimary = dynamicColor(
        light: MinimalColors.textPrimary,
        dark: MinimalColors.Dark.textPrimary
    )
    
    static let minimalTextSecondary = dynamicColor(
        light: MinimalColors.textSecondary,
        dark: MinimalColors.Dark.textSecondary
    )
    
    static let minimalSurface = dynamicColor(
        light: MinimalColors.surface,
        dark: MinimalColors.Dark.surface
    )
    
    static let minimalBorder = dynamicColor(
        light: MinimalColors.border,
        dark: MinimalColors.Dark.border
    )
}