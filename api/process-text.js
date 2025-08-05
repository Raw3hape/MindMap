import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export default async function handler(req, res) {
  console.log('📝 Начался запрос к process-text API (OPTIMIZED)');
  console.log('📋 Метод:', req.method);
  
  // Установка CORS заголовков
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    console.log('✅ Ответ на OPTIONS запрос');
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    console.log('❌ Неподдерживаемый метод:', req.method);
    return res.status(405).json({ success: false, error: 'Метод не поддерживается' });
  }

  try {
    console.log('📦 Полученные данные:', {
      hasText: !!req.body?.text,
      textLength: req.body?.text?.length || 0,
      bodyKeys: Object.keys(req.body || {})
    });
    
    const { text } = req.body;

    if (!text || text.trim().length === 0) {
      console.log('❌ Пустой текст');
      return res.status(400).json({ 
        success: false, 
        error: 'Текст не может быть пустым' 
      });
    }

    // Оптимизированный промпт для GPT-4o-mini
    const prompt = `Проанализируй текст и создай структурированную задачу в JSON формате.

Текст: "${text}"

Создай JSON со следующими полями:
- title: краткий заголовок (макс 50 символов)
- description: подробное описание (если нужно)
- priority: "низкий", "средний" или "высокий"
- subtasks: массив подзадач (макс 5)
- originalText: исходный текст

Правила приоритета:
- "высокий": срочно, важно, deadline, критично, до [дата]
- "низкий": простые задачи без срочности
- "средний": остальные случаи

Примеры:
- "купить молоко и хлеб" → title: "Купить продукты", subtasks: ["Купить молоко", "Купить хлеб"], priority: "низкий"
- "подготовить презентацию к понедельнику" → title: "Подготовить презентацию", priority: "высокий"`;

    console.log('🤖 Отправляем текст в GPT-4o-mini для анализа...', text.substring(0, 50) + '...');
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Новая быстрая модель
      messages: [
        {
          role: 'system',
          content: 'Ты эксперт по планированию задач. Создавай структурированные задачи в JSON формате. Отвечай только валидным JSON без комментариев.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: 400, // Уменьшили для экономии
      temperature: 0.2,
      response_format: { type: 'json_object' } // Гарантированный JSON
    });

    const responseText = completion.choices[0].message.content.trim();
    console.log('📝 Ответ от GPT-4o-mini:', responseText);
    
    try {
      const taskData = JSON.parse(responseText);
      console.log('✅ JSON успешно распарсен:', taskData);
      
      // Валидация и обработка данных
      const processedTask = {
        title: taskData.title || text.substring(0, 50),
        description: taskData.description || null,
        priority: mapPriority(taskData.priority),
        subtasks: Array.isArray(taskData.subtasks) ? taskData.subtasks.slice(0, 5) : [],
        originalText: text
      };

      console.log('🎯 Отправляем успешный ответ:', processedTask.title);
      return res.status(200).json({
        success: true,
        data: processedTask
      });

    } catch (parseError) {
      console.error('❌ Ошибка парсинга JSON:', parseError);
      console.error('📝 Проблемный ответ от OpenAI:', responseText);
      
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
    console.error('💥 Критическая ошибка в process-text:', error);
    console.error('🔍 Стек ошибки:', error.stack);
    
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