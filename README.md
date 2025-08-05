# 🧠 MindMap

> AI-powered iOS app for voice recording and automatic task organization

## 🚀 Быстрый старт с Vercel

### 1. Импорт в Vercel

1. Перейдите на [vercel.com](https://vercel.com)
2. Нажмите "Add New Project"
3. Импортируйте репозиторий: `https://github.com/Raw3hape/MindMap`
4. В настройках окружения добавьте:
   - **OPENAI_API_KEY** = `ваш_ключ_openai`
5. Нажмите "Deploy"
6. Скопируйте URL вашего проекта (например: `https://mindmap-xxx.vercel.app`)

### 2. Настройка iOS приложения

1. Клонируйте репозиторий:
```bash
git clone https://github.com/Raw3hape/MindMap.git
cd MindMap
```

2. Откройте `MindMap/Services/OpenAIService.swift`
3. Замените `baseURL` на ваш Vercel URL:
```swift
private let baseURL = "https://mindmap-xxx.vercel.app/api"
```

4. Откройте `MindMap.xcodeproj` в Xcode
5. Запустите приложение (⌘+R)

## 📱 Функциональность

### Готовые возможности:
- ✅ **Голосовая запись** - нажмите и удерживайте большую кнопку
- ✅ **Текстовый ввод** - альтернативный способ создания задач
- ✅ **AI анализ** - автоматическое создание структурированных задач
- ✅ **Подзадачи** - разбиение сложных задач на шаги
- ✅ **Приоритеты** - автоматическое определение важности
- ✅ **Поиск и фильтры** - быстрый доступ к нужным задачам
- ✅ **Темная тема** - автоматическое переключение
- ✅ **Локальное хранение** - Core Data для офлайн работы

## 🔑 Получение OpenAI API ключа

1. Перейдите на [platform.openai.com](https://platform.openai.com)
2. Войдите или создайте аккаунт
3. Перейдите в [API Keys](https://platform.openai.com/api-keys)
4. Создайте новый ключ
5. Используйте его в Vercel

## ⚙️ Требования

- iOS 15.0+
- Xcode 14+
- OpenAI API ключ
- Vercel аккаунт (бесплатный)

## 🛠 Технологии

- **iOS**: SwiftUI, Core Data, AVFoundation
- **Backend**: Vercel Functions, Node.js
- **AI**: OpenAI GPT-4, Whisper API
- **Архитектура**: MVVM, async/await

## 📂 Структура проекта

```
MindMap/
├── Views/           # UI компоненты
├── ViewModels/      # Бизнес-логика
├── Models/          # Модели данных
├── Services/        # API и сервисы
├── Theme/           # Темы и стили
└── api/             # Vercel функции
```

## 🎨 Кастомизация

### Изменение цветов
Редактируйте файл `Theme/Colors.swift` или цвета в `Assets.xcassets`

### Изменение AI промптов
Обновите промпты в `api/process-text.js`

### Добавление функций
Проект готов к расширению - добавляйте новые ViewModels и Views

## 🐛 Решение проблем

**Ошибка микрофона**: Убедитесь, что дали разрешение на запись аудио в настройках

**API не работает**: Проверьте URL в `OpenAIService.swift` и API ключ в Vercel

**Задачи не сохраняются**: Проверьте Core Data схему в Xcode

---

**GitHub**: [github.com/Raw3hape/MindMap](https://github.com/Raw3hape/MindMap)  
**Создано с помощью**: [Claude Code](https://claude.ai/code)