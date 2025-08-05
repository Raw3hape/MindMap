//
//  MinimalSettingsView.swift
//  MindMap - Минималистичная версия
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

struct MinimalSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAbout = false
    @State private var showingDataClearAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.minimalBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Простой заголовок
                    MinimalSectionHeader(title: "Настройки", count: nil)
                        .padding(.top, 8)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Тема приложения
                            themeSection
                            
                            // Информация о приложении
                            appInfoSection
                            
                            // Управление данными
                            dataSection
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAbout) {
            MinimalAboutView()
        }
        .alert("Удалить все данные?", isPresented: $showingDataClearAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("Это действие нельзя отменить. Все ваши задачи будут удалены.")
        }
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Внешний вид")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.minimalTextPrimary)
            
            VStack(spacing: 12) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    MinimalThemeOption(
                        theme: theme,
                        isSelected: themeManager.currentTheme == theme,
                        onSelect: {
                            themeManager.setTheme(theme)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Приложение")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.minimalTextPrimary)
            
            VStack(spacing: 12) {
                MinimalSettingsRow(
                    title: "О приложении",
                    icon: "info.circle",
                    action: { showingAbout = true }
                )
                
                MinimalSettingsRow(
                    title: "Версия 1.0",
                    icon: "app.badge",
                    action: nil
                )
            }
        }
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Данные")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.minimalTextPrimary)
            
            MinimalActionButton(
                title: "Очистить все данные",
                icon: "trash",
                style: .destructive
            ) {
                showingDataClearAlert = true
            }
        }
    }
    
    // MARK: - Actions
    private func clearAllData() {
        // TODO: Implement data clearing
        // CoreDataManager.shared.clearAllData()
    }
}

// MARK: - Minimal Theme Option
struct MinimalThemeOption: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Иконка темы
                Image(systemName: theme.themeIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .minimalAccent)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.minimalAccent : Color.minimalSurface)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.clear : Color.minimalBorder,
                                lineWidth: 1
                            )
                    )
                
                // Название темы
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.minimalTextPrimary)
                    
                    Text(theme.description)
                        .font(.system(size: 15))
                        .foregroundColor(.minimalTextSecondary)
                }
                
                Spacer()
                
                // Индикатор выбора
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.minimalAccent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.minimalSurface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.minimalAccent : Color.minimalBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Minimal Settings Row
struct MinimalSettingsRow: View {
    let title: String
    let icon: String
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.minimalAccent)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.minimalTextPrimary)
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.minimalTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.minimalSurface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.minimalBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - Minimal About View
struct MinimalAboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.minimalBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Заголовок
                    HStack {
                        Button("Готово") {
                            dismiss()
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.minimalAccent)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    // Логотип и название
                    VStack(spacing: 24) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80, weight: .thin))
                            .foregroundColor(.minimalAccent)
                        
                        VStack(spacing: 8) {
                            Text("MindMap")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.minimalTextPrimary)
                            
                            Text("Версия 1.0")
                                .font(.system(size: 18))
                                .foregroundColor(.minimalTextSecondary)
                        }
                    }
                    
                    // Описание
                    VStack(spacing: 16) {
                        Text("Простое приложение для создания\nзадач с помощью голоса и ИИ")
                            .font(.system(size: 18))
                            .foregroundColor(.minimalTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Создано с SwiftUI")
                            .font(.system(size: 16))
                            .foregroundColor(.minimalTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Копирайт
                    VStack(spacing: 4) {
                        Text("© 2025 MindMap")
                            .font(.system(size: 14))
                            .foregroundColor(.minimalTextSecondary)
                        
                        Text("Разработано Nikita Sergyshkin")
                            .font(.system(size: 14))
                            .foregroundColor(.minimalTextSecondary)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - AppTheme Extension
extension AppTheme {
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Светлая тема"
        case .dark: return "Темная тема"
        case .system: return "Как в системе"
        }
    }
}

#Preview {
    MinimalSettingsView()
        .environmentObject(ThemeManager.shared)
}

#Preview("Dark Mode") {
    MinimalSettingsView()
        .preferredColorScheme(.dark)
        .environmentObject(ThemeManager.shared)
}