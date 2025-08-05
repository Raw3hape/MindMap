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
    const { text } = req.body;

    if (!text || text.trim().length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Текст не может быть пустым' 
      });
    }

    // Используем GPT для анализа текста и создания структурированной задачи
    const prompt = `
Проанализируй следующий текст и создай структурированную задачу в формате JSON.

Текст: "${text}"

Верни JSON объект со следующими полями:
- title: краткий заголовок задачи (максимум 50 символов)
- description: детальное описание задачи (если есть дополнительная информация)
- priority: приоритет (низкий, средний, высокий) на основе анализа важности и срочности
- subtasks: массив подзадач, если задача может быть разбита на части
- originalText: исходный текст

Правила анализа:
1. Если в тексте есть слова "срочно", "важно", "критично", "deadline", "до [дата]" - приоритет высокий
2. Если задача простая и не требует немедленного выполнения - приоритет низкий  
3. В остальных случаях - средний приоритет
4. Если задача сложная, разбей её на логические подзадачи (максимум 5)
5. Заголовок должен быть конкретным и информативным

Примеры:
- "купить молоко и хлеб" → title: "Купить продукты", subtasks: ["Купить молоко", "Купить хлеб"], priority: "низкий"
- "подготовить презентацию к понедельнику" → title: "Подготовить презентацию", priority: "высокий", subtasks: ["Создать структуру", "Подготовить слайды", "Отрепетировать"]
- "запланировать отпуск" → title: "Запланировать отпуск", priority: "средний", subtasks: ["Выбрать даты", "Забронировать билеты", "Забронировать отель"]

Отвечай только валидным JSON объектом:`;

    const completion = await openai.createChatCompletion({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'Ты эксперт по планированию задач. Анализируй текст и создавай структурированные задачи. Отвечай только валидным JSON без дополнительных комментариев.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: 600,
      temperature: 0.2,
    });

    const responseText = completion.data.choices[0].message.content.trim();
    
    try {
      // Убираем возможные markdown блоки кода
      const cleanedResponse = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
      const taskData = JSON.parse(cleanedResponse);
      
      // Валидация и обработка данных
      const processedTask = {
        title: taskData.title || text.substring(0, 50),
        description: taskData.description || null,
        priority: mapPriority(taskData.priority),
        subtasks: Array.isArray(taskData.subtasks) ? taskData.subtasks.slice(0, 5) : [],
        originalText: text
      };

      return res.status(200).json({
        success: true,
        data: processedTask
      });

    } catch (parseError) {
      console.error('Ошибка парсинга JSON:', parseError);
      console.error('Ответ от OpenAI:', responseText);
      
      // Fallback: создаем базовую задачу
      const fallbackTask = {
        title: text.substring(0, 50),
        description: text.length > 50 ? text : null,
        priority: 'средний',
        subtasks: [],
        originalText: text
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
  const highPriority = ['высокий', 'high', 'urgent', 'срочный', 'важный', 'критично'];
  
  const priorityLower = priority.toLowerCase();
  
  if (lowPriority.some(p => priorityLower.includes(p))) {
    return 'низкий';
  }
  
  if (highPriority.some(p => priorityLower.includes(p))) {
    return 'высокий';
  }
  
  return 'средний';
}