# 🔧 Быстрое исправление переводов кнопок

## Проблема
Кнопки отображаются как `[ru.user.associated_accounts.connect]` вместо "Подключить"

## Быстрое решение

### 1. Перезапустите Discourse
```bash
# В директории Discourse
./launcher rebuild app
# или для development
bundle exec rails server
```

### 2. Очистите кэш
- Очистите кэш браузера (Ctrl+Shift+R)
- Или откройте страницу в приватном режиме

### 3. Проверьте результат
1. Перейдите в **Настройки** → **Аккаунт**
2. Найдите раздел **Связанные аккаунты**
3. **ОЖИДАЕТСЯ**: Кнопка показывает "Подключить" (не ключ перевода)

## Что было исправлено

### ✅ В версии 1.1.4:
- Расширены файлы переводов `client.ru.yml` и `server.ru.yml`
- Добавлена принудительная регистрация переводов на сервере
- Создан JavaScript инициализатор для клиентской стороны
- Исправлена структура ключей переводов

### 📁 Новые файлы:
- `assets/javascripts/discourse/initializers/telegram-auth-translations.js`
- Обновленные `config/locales/client.ru.yml` и `server.ru.yml`

## Проверка работы

### ✅ Должно работать:
- [ ] Кнопка "Подключить" на русском языке
- [ ] Кнопка "Отключить" на русском языке  
- [ ] Подтверждение "Отключить этот аккаунт?" на русском
- [ ] Статус "Подключен как @username" на русском

### 🔍 В консоли браузера должно быть:
```
TelegramAuth: Russian translations registered
```

### 🔍 В логах Discourse должно быть:
```
TelegramAuth: Translations registered
```

## Если не работает

### 1. Принудительная очистка кэша
```javascript
// В консоли браузера
localStorage.clear();
sessionStorage.clear();
location.reload(true);
```

### 2. Проверьте загрузку JavaScript
- Откройте Developer Tools (F12)
- Вкладка Network
- Обновите страницу
- Найдите `telegram-auth-translations.js` в списке загруженных файлов

### 3. Ручное применение переводов
```javascript
// В консоли браузера
I18n.translations.ru = I18n.translations.ru || {};
I18n.translations.ru.js = I18n.translations.ru.js || {};
I18n.translations.ru.js.user = I18n.translations.ru.js.user || {};
I18n.translations.ru.js.user.associated_accounts = {
  connect: "Подключить",
  disconnect: "Отключить",
  revoke: "Отключить"
};
location.reload();
```

## Контакты
- **Версия**: 1.1.4
- **Исправление**: Русские переводы для кнопок OAuth
- **Дата**: 6 июня 2025 г.

---
**Примечание**: После применения исправления кнопки должны отображаться на корректном русском языке без ключей переводов.
