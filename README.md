# MindMap - Умный органайзер задач

Интеллектуальное iOS приложение для создания и организации задач с помощью голосовых команд и искусственного интеллекта.

## Возможности

- 🎤 **Голосовая запись**: Создавайте задачи через голосовые команды
- 🧠 **ИИ-анализ**: Автоматическое структурирование задач с помощью OpenAI
- 📋 **Подзадачи**: Автоматическое разбиение сложных задач на подзадачи
- 🎯 **Приоритеты**: Умное определение приоритетов на основе контекста
- 🌓 **Темы**: Поддержка светлой и темной темы
- 💾 **Core Data**: Локальное хранение данных

## Технологии

### iOS App
- SwiftUI + MVVM архитектура
- Core Data для хранения данных
- AVFoundation для записи аудио
- Combine для реактивного программирования

### Backend API
- Vercel Functions (Node.js)
- OpenAI GPT-3.5-turbo для анализа текста
- OpenAI Whisper для транскрипции аудио

## Установка и запуск

### iOS App

1. Откройте проект в Xcode
2. Установите необходимые зависимости
3. Запустите на симуляторе или устройстве

### API

1. Установите зависимости:
```bash
npm install
```

2. Создайте `.env` файл:
```bash
cp .env.example .env
```

3. Добавьте ваш OpenAI API ключ в `.env`

4. Запустите локально:
```bash
npm run dev
```

5. Деплой на Vercel:
```bash
vercel --prod
```

## Настройка OpenAI

1. Зарегистрируйтесь на https://platform.openai.com
2. Получите API ключ
3. Добавьте ключ в настройки Vercel или `.env` файл

## API Endpoints

### POST /api/process-audio
Обрабатывает аудио запись и возвращает структурированную задачу.

**Параметры:**
```json
{
  "audioData": "base64_encoded_audio",
  "mimeType": "audio/m4a"
}
```

### POST /api/process-text
Анализирует текст и создает структурированную задачу.

**Параметры:**
```json
{
  "text": "Текст задачи"
}
```

**Ответ:**
```json
{
  "success": true,
  "data": {
    "title": "Заголовок задачи",
    "description": "Описание",
    "priority": "высокий",
    "subtasks": ["Подзадача 1", "Подзадача 2"],
    "originalText": "Исходный текст"
  }
}
```

## Структура проекта

```
MindMap/
├── MindMap/                    # iOS App
│   ├── Models/                 # Модели данных
│   ├── Views/                  # SwiftUI представления
│   ├── ViewModels/             # MVVM ViewModels
│   ├── Services/               # Сервисы (API, Core Data, Audio)
│   └── Theme/                  # Система тем
├── api/                        # Vercel API функции
│   ├── process-audio.js        # Обработка аудио
│   └── process-text.js         # Обработка текста
└── README.md
```

## Конфигурация

### iOS App
Обновите URL в `OpenAIService.swift`:
```swift
private let baseURL = "https://your-vercel-app.vercel.app"
```

### Vercel
Добавьте переменную окружения `OPENAI_API_KEY` в настройках проекта.

## Лицензия

MIT License

## Автор

Nikita Sergyshkin