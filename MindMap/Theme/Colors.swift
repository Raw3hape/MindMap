//
//  Colors.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

// MARK: - App Colors
struct AppColors {
    // MARK: - Primary Colors
    static let primary = Color("AppPrimary")
    static let secondary = Color.blue
    static let accent = Color("AppPrimary")
    
    // MARK: - Background Colors
    static let background = Color("Background")
    static let backgroundSecondary = Color("Background")
    static let surface = Color("Surface")
    
    // MARK: - Text Colors
    static let text = Color("Text")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextSecondary").opacity(0.7)
    
    // MARK: - Status Colors
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    static let info = Color("Info")
    
    // MARK: - Priority Colors
    static let priorityLow = Color.green
    static let priorityMedium = Color.orange
    static let priorityHigh = Color.red
    
    // MARK: - Recording Colors
    static let recordingActive = Color.red
    static let recordingInactive = Color.gray
    static let recordingBackground = Color.black.opacity(0.1)
    
    // MARK: - Task Colors
    static let taskCompleted = Color.green.opacity(0.2)
    static let taskPending = Color.blue.opacity(0.1)
    
    // MARK: - Border Colors
    static let border = Color.gray.opacity(0.3)
    static let borderActive = Color.blue
    
    // MARK: - Shadow Colors
    static let shadowLight = Color.black.opacity(0.1)
    static let shadowMedium = Color.black.opacity(0.2)
    static let shadowDark = Color.black.opacity(0.3)
}

// MARK: - Gradient Definitions
extension AppColors {
    static let primaryGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [background, backgroundSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let recordingGradient = RadialGradient(
        colors: [recordingActive, recordingActive.opacity(0.3)],
        center: .center,
        startRadius: 20,
        endRadius: 100
    )
}

// MARK: - Dynamic Colors for Light/Dark Mode
extension Color {
    static let dynamicBackground = Color(
        light: Color(red: 0.98, green: 0.98, blue: 0.98),
        dark: Color(red: 0.1, green: 0.1, blue: 0.1)
    )
    
    static let dynamicSurface = Color(
        light: Color.white,
        dark: Color(red: 0.15, green: 0.15, blue: 0.15)
    )
    
    static let dynamicText = Color(
        light: Color.black,
        dark: Color.white
    )
    
    static let dynamicTextSecondary = Color(
        light: Color.gray,
        dark: Color.gray
    )
}

// MARK: - Color Initializer Helper
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}