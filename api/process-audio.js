// Упрощенный редирект на process-text API
// Аудио теперь обрабатывается iOS Speech Recognition

export default async function handler(req, res) {
  console.log('🔄 process-audio: Редирект на process-text API');
  
  // Установка CORS заголовков
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    console.log('✅ OPTIONS запрос обработан');
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    console.log('❌ Неподдерживаемый метод:', req.method);
    return res.status(405).json({ 
      success: false, 
      error: 'Метод не поддерживается. Используйте POST.' 
    });
  }

  try {
    const { text } = req.body;

    if (!text || text.trim().length === 0) {
      console.log('❌ Пустой текст в запросе');
      return res.status(400).json({ 
        success: false, 
        error: 'Текст не может быть пустым. Используйте iOS Speech Recognition для получения текста из аудио.' 
      });
    }

    console.log('📝 Получен текст для обработки:', text.substring(0, 50) + '...');

    // Создаем внутренний запрос к process-text
    const textApiUrl = `${req.headers['x-forwarded-proto'] || 'https'}://${req.headers.host}/api/process-text`;
    
    console.log('🌐 Переадресация на:', textApiUrl);

    const response = await fetch(textApiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ text })
    });

    const result = await response.json();
    
    console.log('✅ Ответ от process-text получен:', response.status);
    
    return res.status(response.status).json(result);

  } catch (error) {
    console.error('💥 Ошибка редиректа:', error);
    
    return res.status(500).json({
      success: false,
      error: 'Ошибка перенаправления на text API: ' + error.message
    });
  }
}