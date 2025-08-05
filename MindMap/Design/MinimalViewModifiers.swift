//
//  MinimalViewModifiers.swift
//  MindMap - Минималистичная версия
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import SwiftUI

// MARK: - Минималистичные модификаторы View

// Модификатор для фона с градиентом
struct MinimalBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.minimalBackground)
    }
}

// Модификатор для карточки
struct MinimalCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 2) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(Color.minimalSurface)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.minimalBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: shadowRadius, x: 0, y: 1)
    }
}

// Модификатор для больших тач-таргетов
struct MinimalTouchTargetModifier: ViewModifier {
    let minHeight: CGFloat
    
    init(minHeight: CGFloat = 44) {
        self.minHeight = minHeight
    }
    
    func body(content: Content) -> some View {
        content
            .frame(minHeight: minHeight)
    }
}

// Модификатор для анимации нажатия
struct MinimalTapAnimationModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

// Модификатор для типографики заголовков
struct MinimalHeadlineModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    init(size: CGFloat = 24, weight: Font.Weight = .semibold) {
        self.size = size
        self.weight = weight
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .foregroundColor(.minimalTextPrimary)
    }
}

// Модификатор для типографики подзаголовков
struct MinimalSubheadlineModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17))
            .foregroundColor(.minimalTextSecondary)
    }
}

// Модификатор для капции
struct MinimalCaptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14))
            .foregroundColor(.minimalTextSecondary)
    }
}

// MARK: - Расширения View для удобства использования

extension View {
    func minimalBackground() -> some View {
        modifier(MinimalBackgroundModifier())
    }
    
    func minimalCard(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 2) -> some View {
        modifier(MinimalCardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
    
    func minimalTouchTarget(minHeight: CGFloat = 44) -> some View {
        modifier(MinimalTouchTargetModifier(minHeight: minHeight))
    }
    
    func minimalTapAnimation() -> some View {
        modifier(MinimalTapAnimationModifier())
    }
    
    func minimalHeadline(size: CGFloat = 24, weight: Font.Weight = .semibold) -> some View {
        modifier(MinimalHeadlineModifier(size: size, weight: weight))
    }
    
    func minimalSubheadline() -> some View {
        modifier(MinimalSubheadlineModifier())
    }
    
    func minimalCaption() -> some View {
        modifier(MinimalCaptionModifier())
    }
}

// MARK: - Анимации для минималистичного дизайна

extension Animation {
    static let minimalEaseInOut = Animation.easeInOut(duration: 0.3)
    static let minimalSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let minimalQuick = Animation.easeInOut(duration: 0.15)
}

// MARK: - Конфигурация отступов

struct MinimalSpacing {
    static let tiny: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let huge: CGFloat = 48
}

// MARK: - Конфигурация размеров

struct MinimalSizes {
    static let touchTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 52
    static let cardCornerRadius: CGFloat = 16
    static let iconSize: CGFloat = 24
    static let largeIconSize: CGFloat = 48
}

// MARK: - Предустановленные стили кнопок

struct MinimalButtonStyles {
    
    // Основная кнопка
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: MinimalSizes.buttonHeight)
                .background(Color.minimalAccent)
                .cornerRadius(MinimalSizes.cardCornerRadius)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.minimalQuick, value: configuration.isPressed)
        }
    }
    
    // Вторичная кнопка
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.minimalTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: MinimalSizes.buttonHeight)
                .background(Color.minimalSurface)
                .cornerRadius(MinimalSizes.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: MinimalSizes.cardCornerRadius)
                        .strokeBorder(Color.minimalBorder, lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.minimalQuick, value: configuration.isPressed)
        }
    }
    
    // Деструктивная кнопка
    struct DestructiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: MinimalSizes.buttonHeight)
                .background(Color.error)
                .cornerRadius(MinimalSizes.cardCornerRadius)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.minimalQuick, value: configuration.isPressed)
        }
    }
}

// MARK: - Расширения ButtonStyle для удобства

extension View {
    func minimalPrimaryButtonStyle() -> some View {
        self.buttonStyle(MinimalButtonStyles.PrimaryButtonStyle())
    }
    
    func minimalSecondaryButtonStyle() -> some View {
        self.buttonStyle(MinimalButtonStyles.SecondaryButtonStyle())
    }
    
    func minimalDestructiveButtonStyle() -> some View {
        self.buttonStyle(MinimalButtonStyles.DestructiveButtonStyle())
    }
}