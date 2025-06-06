# 🔍 Тест функциональности Telegram Auth

## Что должно происходить при переходе на /auth/telegram

### ✅ Ожидаемое поведение:
1. **Страница загружается** без ошибок
2. **Появляется виджет Telegram** - синяя кнопка "Log in with Telegram"
3. **При нажатии на виджет** - открывается Telegram (приложение или веб-версия)
4. **В Telegram** - запрос на подтверждение входа
5. **После подтверждения** - редирект обратно на Discourse с авторизацией

### ❌ Проблемы, которые могут возникнуть:

#### 1. Виджет не появляется
**Причины:**
- Не загружается `https://telegram.org/js/telegram-widget.js`
- Ошибки в CSP (Content Security Policy)
- Неправильные настройки бота

#### 2. Виджет появляется, но не работает
**Причины:**
- Домен не привязан к боту в @BotFather
- Неправильный bot token или bot name
- Блокировка CORS

#### 3. Ошибка "signature mismatch"
**Причины:**
- Неправильный токен бота
- Проблемы с валидацией подписи

## Диагностика

### Шаг 1: Проверка основных настроек
```bash
# В Rails console Discourse
puts "Плагин включен: #{SiteSetting.telegram_auth_enabled}"
puts "Bot name: #{SiteSetting.telegram_auth_bot_name}"
puts "Bot token настроен: #{SiteSetting.telegram_auth_bot_token.present?}"
```

### Шаг 2: Проверка в браузере
1. Откройте `https://yourdomain.com/auth/telegram`
2. Откройте Developer Tools (F12)
3. Проверьте Console на ошибки
4. Проверьте Network tab - загружается ли telegram-widget.js

### Шаг 3: Проверка CSP
Убедитесь, что в настройках CSP разрешен домен telegram.org:
```
Content-Security-Policy: script-src 'self' https://telegram.org
```

### Шаг 4: Проверка настроек бота
1. Отправьте `/setdomain` боту @BotFather
2. Выберите вашего бота
3. Укажите точный домен вашего сайта

## Возможное решение

Если виджет не появляется, возможно, нужно добавить HTML-template для отображения виджета Telegram. Давайте проверим, есть ли у нас соответствующий template или нужно его создать.

## Быстрый тест

### Тест 1: Прямая проверка OmniAuth
```bash
curl -I https://yourdomain.com/auth/telegram
```
**Ожидается:** HTTP 200 или редирект

### Тест 2: Проверка загрузки виджета
```javascript
// В консоли браузера на странице /auth/telegram
console.log('Telegram widget script loaded:', !!window.Telegram);
```

### Тест 3: Проверка настроек в коде
```ruby
# В Rails console
authenticator = TelegramAuthenticator.new
puts "Authenticator enabled: #{authenticator.enabled?}"
puts "Connect path: #{authenticator.connect_path}"
```

## Статус

- [ ] Виджет отображается на /auth/telegram
- [ ] Виджет кликабелен и открывает Telegram
- [ ] Аутентификация проходит успешно
- [ ] Пользователь входит в Discourse

---
**Примечание:** Если ни один из пунктов не работает, нужно добавить frontend-компоненты для отображения Telegram виджета.
