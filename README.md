# 🧠 MindMap v2.0

> AI-powered iOS app с упрощенной архитектурой (без Whisper)

## 🚀 Обновления v2.0

- ❌ **Убрали Whisper API** - больше не используется
- ✅ **iOS Speech Recognition** - встроенное распознавание речи
- ✅ **Только GPT анализ** - быстрее и дешевле
- ✅ **Приватность** - аудио не покидает устройство

## 🏗️ Новая архитектура

```
📱 iOS App (Speech Recognition) 
    ↓ 
📝 Текст 
    ↓ 
🌐 Vercel API 
    ↓ 
🤖 GPT-4o-mini 
    ↓ 
✅ Структурированные задачи
```

## 🌐 Deployment

**Текущий URL**: `https://mind-piex2dd9o-nikitas-projects-3a31754b.vercel.app`

### API Endpoints:

- **POST `/api/process-text`** - основной анализ текста
- **POST `/api/process-audio`** - редирект на process-text (совместимость)

## 📱 iOS Настройки

**Обновите URL в коде:**
```swift
// MindMap/Services/OpenAIService.swift
private let baseURL = "https://mind-piex2dd9o-nikitas-projects-3a31754b.vercel.app"
```

## 🔑 Vercel Настройки

1. **Environment Variables**: OPENAI_API_KEY (уже настроен)
2. **Public Access**: Включен в vercel.json
3. **CORS**: Настроен для всех источников
4. **Functions**: Оптимизированы таймауты

## ✨ Преимущества v2.0

- ⚡ **Быстрее** - нет загрузки аудио файлов
- 💰 **Дешевле** - только GPT-4o-mini вместо Whisper + GPT
- 🔒 **Приватнее** - аудио обрабатывается на устройстве
- 📱 **Надежнее** - меньше зависимостей от внешних API

## 🛠 Технологии

- **iOS**: SwiftUI, Core Data, Speech Framework
- **Backend**: Vercel Serverless Functions
- **AI**: OpenAI GPT-4o-mini
- **Архитектура**: MVVM, async/await

## 📂 API Структура

```
api/
├── process-text.js     # Основной анализ текста
└── process-audio.js    # Редирект (совместимость)
```

## 🔧 Требования

- iOS 15.0+ (для Speech Recognition)
- Xcode 14+
- OpenAI API ключ
- Vercel аккаунт

## 🐛 Troubleshooting v2.0

**Speech Recognition не работает**: Проверьте разрешения в настройках iOS

**API требует аутентификацию**: Убедитесь что в vercel.json установлен `"public": true`

**404 на API**: Проверьте что функции задеплоены корректно

---

**Миграция**: Если обновляетесь с v1.0, просто обновите URL в iOS коде  
**GitHub**: [github.com/Raw3hape/MindMap](https://github.com/Raw3hape/MindMap)  
**Создано с помощью**: [Claude Code](https://claude.ai/code)