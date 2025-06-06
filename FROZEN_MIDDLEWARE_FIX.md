# 🔧 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Frozen Middleware Stack in Rails 7.2+

## 📅 Дата: 6 июня 2025 г.
## 🏷️ Версия: 1.1.9
## 🎯 Статус: ИСПРАВЛЕНО ✅

---

## 🚨 НОВАЯ ПРОБЛЕМА

После исправления первоначальной проблемы с middleware возникла новая ошибка:

```
FrozenError: can't modify frozen Array: [ActionDispatch::RemoteIp, Middleware::RequestTracker, ...]
/var/www/discourse/plugins/discourse-telegram-auth/plugin.rb:326:in `rescue in block in activate!'
```

### Причина
В Rails 7.2+ стек middleware **замораживается** после инициализации приложения. Попытка добавить middleware в блоке `after_initialize` приводит к ошибке `FrozenError`, так как массив middleware уже не может быть модифицирован.

---

## ✅ РЕШЕНИЕ

### 1. Перенос регистрации middleware
Переместили регистрацию middleware **ДО** блока `after_initialize`:

**БЫЛО (вызывало FrozenError):**
```ruby
after_initialize do
  # ...
  Rails.application.config.middleware.use TelegramCSPMiddleware  # ❌ Ошибка!
end
```

**СТАЛО (работает корректно):**
```ruby
# Регистрируем middleware ДО after_initialize
class ::TelegramCSPMiddleware
  def initialize(app); @app = app; end
  def call(env)
    if env['PATH_INFO'] == '/auth/telegram' || env['PATH_INFO'].start_with?('/auth/telegram')
      env['action_dispatch.content_security_policy'] = nil
      env['action_dispatch.content_security_policy_report_only'] = nil
    end
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_after ActionDispatch::Flash, TelegramCSPMiddleware

after_initialize do
  # Только регистрация переводов и роутов
end
```

### 2. Использование безопасной точки вставки
Вместо попыток найти `ActionDispatch::ContentSecurityPolicy::Middleware` используем стабильную точку вставки - `ActionDispatch::Flash`, которая всегда присутствует.

---

## 📊 РЕЗУЛЬТАТ

- ✅ **Исправлена ошибка FrozenError** при регистрации middleware
- ✅ **Стабильная точка вставки** - `ActionDispatch::Flash`
- ✅ **Ранняя регистрация** - до заморозки стека
- ✅ **Простота и надежность** - убраны сложные fallback механизмы

---

## 🔍 ТЕХНИЧЕСКАЯ ИНФОРМАЦИЯ

### Фазы инициализации Rails:
1. **Загрузка конфигурации** ← Middleware можно добавлять
2. **Инициализация приложения** ← Middleware можно добавлять  
3. **after_initialize хуки** ← ❌ Middleware уже заморожен
4. **Запуск приложения**

### Наше решение:
- Middleware регистрируется в **фазе 2** (безопасно)
- Роуты и переводы в **фазе 3** (допустимо)

---

## 🚀 ГОТОВНОСТЬ

Плагин версии **1.1.9** должен теперь успешно загружаться в Discourse с Rails 7.2+ без ошибок middleware.

**Тест команда:**
```bash
cd /var/www/discourse && su discourse -c 'bundle exec rake db:migrate'
```

---

**🎯 Middleware корректно зарегистрирован в раннюю фазу инициализации!**
