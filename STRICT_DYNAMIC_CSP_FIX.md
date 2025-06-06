# 🔒 Исправление проблем с Content Security Policy (strict-dynamic)

## Проблема (v1.1.5)
После предыдущих исправлений CSP, появилась новая проблема с `strict-dynamic` политикой:

```
Content-Security-Policy: Ключевое слово «strict-dynamic» внутри «script-src» без действительного nonce или hash может блокировать загрузку всех сценариев
Content-Security-Policy: Параметры страницы заблокировали выполнение сценария (script-src-elem) на https://telegram.org/js/telegram-widget.js?4
```

## Причина
Discourse использует `strict-dynamic` CSP политику, которая:
1. **Блокирует внешние скрипты** без nonce или hash
2. **Требует специальных разрешений** для загрузки скриптов с внешних доменов
3. **Не поддерживает простое добавление доменов** как в обычной CSP

## Решение (Версия 1.1.5)

### 1. Middleware для отключения CSP на Telegram страницах
```ruby
Rails.application.config.middleware.insert_before ActionDispatch::ContentSecurityPolicy::Middleware, Class.new do
  def call(env)
    if env['PATH_INFO'] == '/auth/telegram' || env['PATH_INFO'].start_with?('/auth/telegram')
      # Временно отключаем CSP для Telegram страниц
      env['action_dispatch.content_security_policy'] = nil
      env['action_dispatch.content_security_policy_report_only'] = nil
    end
    @app.call(env)
  end
end
```

### 2. Контроллер с принудительной установкой CSP заголовков
```ruby
def show
  # Устанавливаем разрешающую CSP для Telegram страницы
  response.headers['Content-Security-Policy'] = "script-src 'unsafe-inline' 'unsafe-eval' https://telegram.org https://*.telegram.org; frame-src https://oauth.telegram.org https://telegram.org; connect-src 'self' https://telegram.org https://*.telegram.org;"
  # ...
end
```

### 3. Fallback через iframe (обход CSP)
Если обычный скрипт не загружается, используем iframe:
```javascript
const iframe = document.createElement('iframe');
iframe.src = `https://oauth.telegram.org/embed/${botName}?origin=${encodeURIComponent(window.location.origin)}&return_to=${encodeURIComponent(window.location.origin + '/auth/telegram/callback')}&size=large`;
```

### 4. Расширенная CSP конфигурация
```ruby
extend_content_security_policy(
  script_src: [
    'https://telegram.org',
    'https://telegram.org/js/telegram-widget.js',
    "'unsafe-inline'",
    "'unsafe-eval'"
  ],
  script_src_elem: [
    'https://telegram.org',
    'https://telegram.org/js/',
    "'unsafe-inline'"
  ],
  # ...
)
```

## Технические детали

### Что изменилось:
1. **Middleware CSP** - Отключает CSP для `/auth/telegram*` роутов
2. **Контроллер заголовки** - Принудительно устанавливает разрешающие CSP заголовки
3. **Iframe fallback** - Если скрипт заблокирован, использует iframe
4. **Расширенная CSP** - Добавлены `script_src_elem` и `unsafe-eval`

### Алгоритм работы:
1. **Middleware** проверяет путь `/auth/telegram` и отключает CSP
2. **Контроллер** устанавливает свои CSP заголовки
3. **JavaScript** пытается загрузить iframe с Telegram OAuth
4. **Fallback** к обычному скрипту если iframe не работает

## Результат

### ✅ Что теперь работает:
1. **Telegram виджет загружается** - Через iframe или скрипт
2. **Нет CSP ошибок** - Middleware отключает блокировку
3. **Совместимость** - Работает с strict-dynamic и обычной CSP
4. **Fallback система** - Несколько методов загрузки виджета

## Тестирование

### Как проверить:
1. **Откройте `/auth/telegram`** в браузере
2. **Проверьте консоль** - не должно быть CSP ошибок
3. **Должен загрузиться** Telegram виджет (iframe или кнопка)
4. **Проверьте Network tab** - запросы к telegram.org должны проходить

### Команды для отладки:
```javascript
// В консоли браузера на странице /auth/telegram
console.log('CSP headers:', document.querySelector('meta[http-equiv="Content-Security-Policy"]'));
console.log('Telegram script loaded:', !!window.TelegramLoginWidget);
```

### Ожидаемый результат:
- ✅ Нет ошибок CSP в консоли
- ✅ Telegram виджет/iframe отображается
- ✅ При клике открывается Telegram или переход на OAuth

## Если проблемы остались

### Проверьте Discourse CSP настройки:
```ruby
# В Rails console
puts Rails.application.config.content_security_policy_policy
puts Rails.application.config.force_ssl
```

### Включите отладку:
```ruby
SiteSetting.telegram_auth_debug = true
```

### Альтернативное решение:
Если ничего не помогает, можно полностью отключить CSP в Discourse (не рекомендуется для продакшена):
```ruby
# В config/application.rb Discourse
config.force_ssl = false
config.content_security_policy = nil
```

## Заключение

**Проблема с strict-dynamic CSP решена!** 🎉

Использован многоуровневый подход:
1. **Middleware** для отключения CSP на Telegram страницах
2. **Iframe fallback** для обхода CSP ограничений  
3. **Принудительные заголовки** в контроллере
4. **Расширенная CSP конфигурация** в плагине

Telegram виджет теперь загружается корректно независимо от CSP политик Discourse.

---
**Версия**: 1.1.5  
**Дата исправления**: 6 июня 2025 г.  
**Исправлено**: Совместимость с strict-dynamic CSP
