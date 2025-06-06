# Быстрое решение проблемы зависания

## Ваша проблема
URL `https://gig.ovh/auth/telegram?reconnect=true` зависает и не работает.

## Немедленные действия

### 1. Проверьте настройки бота в @BotFather
```
/setdomain
Выберите бота → введите: gig.ovh
```

### 2. Проверьте настройки Discourse
В админ-панели:
- `telegram_auth_enabled` ✅ включено
- `telegram_auth_bot_name` → имя бота (например: `MyBot`)  
- `telegram_auth_bot_token` → токен из @BotFather

### 3. Попробуйте без reconnect параметра
Вместо `https://gig.ovh/auth/telegram?reconnect=true`  
Используйте: `https://gig.ovh/auth/telegram`

### 4. Проверьте консоль браузера
1. Нажмите F12
2. Перейдите на вкладку Console  
3. Обновите страницу
4. Посмотрите на ошибки

## Частые причины

❌ **Домен не привязан к боту**  
✅ Отправьте `/setdomain` в @BotFather

❌ **Неправильный формат токена**  
✅ Токен должен быть вида: `123456789:ABCdefGHI...`

❌ **CSP блокирует Telegram скрипт**  
✅ Проверьте ошибки в консоли браузера

❌ **Плагин не активен**  
✅ Проверьте в админ-панели → Plugins

## Если не помогает

1. Включите debug режим: `telegram_auth_debug = true`
2. Перезагрузите сайт: `./launcher rebuild app`  
3. Проверьте логи: `./launcher logs app`
4. Используйте файл `TROUBLESHOOTING.md` для детальной диагностики

## Проверка работоспособности

Если все настроено правильно, на странице `/auth/telegram` должен появиться синий виджет "Log in with Telegram".
