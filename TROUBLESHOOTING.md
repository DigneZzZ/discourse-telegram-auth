# Устранение проблемы зависания Telegram Auth

## Проблема
Страница зависает при переходе на `https://gig.ovh/auth/telegram?reconnect=true` и не идет дальше.

## Возможные причины

### 1. Неправильная конфигурация бота

**Проверьте настройки в админ-панели Discourse:**
- `telegram_auth_enabled` = true
- `telegram_auth_bot_name` = имя вашего бота (например: `YourBotName_bot`)
- `telegram_auth_bot_token` = токен бота из @BotFather

### 2. Домен не привязан к боту

**Исправление:**
1. Откройте @BotFather в Telegram
2. Отправьте команду `/setdomain`
3. Выберите вашего бота
4. Укажите домен: `gig.ovh` (без https://)

### 3. Content Security Policy блокирует виджет

**Проверьте в консоли браузера:**
- Откройте F12 → Console
- Ищите ошибки типа "Content Security Policy directive"

**Если есть CSP ошибки, убедитесь что в plugin.rb есть:**
```ruby
extend_content_security_policy script_src: ['https://telegram.org/js/telegram-widget.js']
```

### 4. JavaScript ошибки

**Диагностика:**
1. Откройте F12 → Console
2. Скопируйте и выполните код из файла `debug.js`
3. Посмотрите результаты диагностики

### 5. Проблемы с middleware

**В логах Rails ищите ошибки:**
```bash
tail -f log/production.log | grep -i telegram
```

## Пошаговая диагностика

### Шаг 1: Проверка конфигурации

1. Включите debug режим:
   ```
   telegram_auth_debug = true
   ```

2. Перезагрузите приложение:
   ```bash
   ./launcher rebuild app
   ```

### Шаг 2: Проверка настроек бота

**Формат имени бота:** должно заканчиваться на `bot` или `Bot`
- ✅ Правильно: `MyAwesomeBot`
- ❌ Неправильно: `MyAwesome`

**Формат токена:** `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
- Должен содержать 8-10 цифр, двоеточие, затем 35 символов

### Шаг 3: Проверка браузера

1. Откройте консоль разработчика (F12)
2. Перейдите на `https://gig.ovh/auth/telegram`
3. Проверьте:
   - Есть ли ошибки в Console
   - Загружается ли `telegram-widget.js` в Network
   - Появляется ли виджет Telegram на странице

### Шаг 4: Проверка сети

Убедитесь, что сервер может подключиться к Telegram:
```bash
curl -I https://telegram.org/js/telegram-widget.js
```

## Частые ошибки и решения

### Ошибка: "Bot domain invalid"
**Решение:** Убедитесь, что домен `gig.ovh` точно привязан к боту в @BotFather

### Ошибка: "CSP directive violated"
**Решение:** Проверьте, что CSP правильно настроен в плагине

### Ошибка: "Telegram widget not found"
**Решение:** Плагин не активен или неправильно настроен

### Страница загружается, но виджет не появляется
**Решение:** 
1. Проверьте JavaScript ошибки
2. Убедитесь, что `telegram-widget.js` загружается
3. Проверьте CSP настройки

## Принудительная диагностика

Если проблема не решается, выполните:

1. **Проверьте логи Rails:**
   ```bash
   tail -f log/production.log
   ```

2. **Выполните диагностику в Rails console:**
   ```ruby
   TelegramAuthenticator.diagnose_setup
   ```

3. **Проверьте состояние плагина:**
   ```ruby
   Discourse.plugins.find { |p| p.name == 'discourse-telegram-auth' }&.enabled?
   ```

## Контрольный список

- [ ] Плагин включен в админ-панели
- [ ] telegram_auth_enabled = true  
- [ ] Правильное имя бота (заканчивается на bot/Bot)
- [ ] Правильный формат токена
- [ ] Домен привязан в @BotFather
- [ ] CSP настроен для telegram-widget.js
- [ ] Нет JavaScript ошибок в консоли
- [ ] telegram-widget.js загружается успешно
- [ ] Логи Rails не содержат ошибок

## Если ничего не помогает

1. Создайте новый тестовый бот в @BotFather
2. Привяжите его к домену `gig.ovh`
3. Обновите настройки в Discourse
4. Проверьте еще раз

Если проблема остается, проверьте версию Discourse и совместимость плагина.
