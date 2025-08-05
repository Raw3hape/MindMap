import { Configuration, OpenAIApi } from 'openai';

const configuration = new Configuration({
  apiKey: process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(configuration);

export default async function handler(req, res) {
  // Установка CORS заголовков
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Метод не поддерживается' });
  }

  try {
    const { audioData, mimeType, text } = req.body;

    let transcribedText = text;

    // Если есть аудио данные, сначала транскрибируем их
    if (audioData && !text) {
      const audioBuffer = Buffer.from(audioData, 'base64');
      
      // Создаем временный файл для OpenAI API
      const FormData = require('form-data');
      const form = new FormData();
      form.append('file', audioBuffer, {
        filename: 'recording.m4a',
        contentType: mimeType || 'audio/m4a'
      });
      form.append('model', 'whisper-1');

      const transcriptionResponse = await openai.createTranscription(
        form.getBuffer(),
        form.getHeaders()
      );

      transcribedText = transcriptionResponse.data.text;
    }

    if (!transcribedText) {
      return res.status(400).json({ 
        success: false, 
        error: 'Не удалось получить текст для обработки' 
      });
    }

    // Используем GPT для анализа текста и создания структурированной задачи
    const prompt = `
Проанализируй следующий текст и создай структурированную задачу в формате JSON.

Текст: "${transcribedText}"

Верни JSON объект со следующими полями:
- title: краткий заголовок задачи (максимум 50 символов)
- description: детальное описание задачи (если есть дополнительная информация)
- priority: приоритет (низкий, средний, высокий) на основе анализа важности и срочности
- subtasks: массив подзадач, если задача может быть разбита на части
- originalText: исходный текст

Примеры:
- Если текст "купить молоко и хлеб завтра", то создай задачу с заголовком "Купить продукты", подзадачами ["Купить молоко", "Купить хлеб"] и средним приоритетом
- Если текст содержит слова "срочно", "важно", "deadline" - установи высокий приоритет
- Если текст простой без временных рамок - установи низкий приоритет

Отвечай только JSON объектом:`;

    const completion = await openai.createChatCompletion({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'Ты помощник для создания структурированных задач. Отвечай только валидным JSON.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: 500,
      temperature: 0.3,
    });

    const responseText = completion.data.choices[0].message.content.trim();
    
    try {
      const taskData = JSON.parse(responseText);
      
      // Валидация и обработка данных
      const processedTask = {
        title: taskData.title || transcribedText.substring(0, 50),
        description: taskData.description || null,
        priority: mapPriority(taskData.priority),
        subtasks: Array.isArray(taskData.subtasks) ? taskData.subtasks : [],
        originalText: transcribedText
      };

      return res.status(200).json({
        success: true,
        data: processedTask
      });

    } catch (parseError) {
      console.error('Ошибка парсинга JSON:', parseError);
      
      // Fallback: создаем базовую задачу
      const fallbackTask = {
        title: transcribedText.substring(0, 50),
        description: transcribedText.length > 50 ? transcribedText : null,
        priority: 'средний',
        subtasks: [],
        originalText: transcribedText
      };

      return res.status(200).json({
        success: true,
        data: fallbackTask
      });
    }

  } catch (error) {
    console.error('Ошибка обработки:', error);
    
    return res.status(500).json({
      success: false,
      error: 'Внутренняя ошибка сервера: ' + error.message
    });
  }
}

// Вспомогательная функция для маппинга приоритетов
function mapPriority(priority) {
  if (!priority) return 'средний';
  
  const lowPriority = ['низкий', 'low', 'normal', 'обычный'];
  const highPriority = ['высокий', 'high', 'urgent', 'срочный', 'важный'];
  
  const priorityLower = priority.toLowerCase();
  
  if (lowPriority.some(p => priorityLower.includes(p))) {
    return 'низкий';
  }
  
  if (highPriority.some(p => priorityLower.includes(p))) {
    return 'высокий';
  }
  
  return 'средний';
}