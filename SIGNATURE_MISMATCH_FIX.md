# Устранение проблем с Signature Mismatch в Telegram Auth

## Обзор проблемы

Проблема "signature mismatch" в Telegram аутентификации возникает когда подпись, полученная от Telegram, не соответствует подписи, вычисленной на стороне сервера. Это критическая проблема безопасности.

## Причины signature mismatch

1. **Неправильный токен бота** - самая частая причина
2. **Отсутствие обязательных полей** (id, auth_date)
3. **Неправильный порядок полей при создании строки для проверки**
4. **Проблемы с кодировкой символов**
5. **Устаревшие данные аутентификации (> 24 часов)**

## Исправления в версии 1.1.0

### 1. Обновлена версия omniauth-telegram до 0.2.1
```ruby
gem 'omniauth-telegram', '0.2.1', require: false
```

Версия 0.2.1 включает исправления:
- `fix 'invalid_signature' with missing username issue`
- `fix 'missing-field' param issue`

### 2. Добавлена дополнительная валидация

```ruby
def validate_telegram_signature(params, bot_token)
  # Проверка наличия обязательных параметров
  return false if params.blank? || bot_token.blank?
  
  # Извлечение и проверка хеша
  received_hash = params['hash']
  return false if received_hash.blank?
  
  # Создание строки для проверки согласно документации Telegram
  hash_fields = %w[auth_date first_name id last_name photo_url username]
  data_check_string = hash_fields
    .select { |field| check_params[field].present? }
    .sort
    .map { |field| "#{field}=#{check_params[field]}" }
    .join("\n")
  
  # Вычисление HMAC-SHA256
  secret_key = OpenSSL::Digest::SHA256.digest(bot_token)
  calculated_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret_key, data_check_string)
  
  received_hash == calculated_hash
end
```

### 3. Улучшенная обработка ошибок

```ruby
def after_authenticate(auth_token, existing_account = nil)
  # Проверка структуры токена
  if auth_token[:uid].blank? || auth_token[:provider] != 'telegram'
    return Auth::Result.new.tap { |r| r.failed = true; r.failed_reason = "Invalid authentication data" }
  end

  # Проверка обязательных полей
  required_fields = ['id', 'auth_date']
  telegram_data = auth_token[:extra][:raw_info] || auth_token[:info] || {}
  
  missing_fields = required_fields.select { |field| telegram_data[field].blank? }
  if missing_fields.any?
    return Auth::Result.new.tap { |r| r.failed = true; r.failed_reason = "Missing required authentication fields" }
  end

  # Проверка актуальности данных (не старше 24 часов)
  auth_date = telegram_data['auth_date'].to_i
  if (Time.now.to_i - auth_date) > 86400
    return Auth::Result.new.tap { |r| r.failed = true; r.failed_reason = "Authentication session expired" }
  end
  
  # ... остальная логика
end
```

## Настройка для отладки

Добавлена настройка `telegram_auth_debug` для детального логирования:

```yaml
telegram_auth_debug:
  default: false
  client: false
  hidden: true
```

При включении этой настройки в логах будут отображаться:
- Строка для проверки подписи
- Полученный хеш от Telegram  
- Вычисленный хеш на сервере
- Дополнительная информация об аутентификации

## Диагностика проблем

### 1. Проверьте токен бота
```bash
# Токен должен иметь формат: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
# Длина: 8-10 цифр, двоеточие, 35 символов base64
```

### 2. Проверьте привязку домена
```bash
# Отправьте команду /setdomain боту @BotFather
# Укажите точный домен вашего сайта
```

### 3. Включите режим отладки
```ruby
SiteSetting.telegram_auth_debug = true
```

### 4. Проверьте логи Rails
```bash
tail -f log/production.log | grep TelegramAuth
```

## Проверка в коде

Добавлен метод для проверки совместимости:

```ruby
def self.discourse_compatibility
  {
    has_user_associated_accounts: defined?(UserAssociatedAccount),
    omniauth_version: Gem.loaded_specs['omniauth']&.version&.to_s,
    telegram_gem_version: Gem.loaded_specs['omniauth-telegram']&.version&.to_s
  }
end
```

## Тестирование

Создан набор тестов для проверки signature validation:

```bash
# Запуск тестов
bundle exec rspec spec/telegram_authenticator_spec.rb
```

## Заключение

Версия 1.1.0 плагина содержит все необходимые исправления для устранения проблем signature mismatch:

1. ✅ Обновлена версия omniauth-telegram до 0.2.1 (последняя доступная)
2. ✅ Добавлена дополнительная валидация подписи 
3. ✅ Улучшена обработка ошибок и логирование
4. ✅ Добавлены проверки обязательных полей
5. ✅ Реализована проверка актуальности данных
6. ✅ Создан набор тестов для валидации

Если проблемы с signature mismatch продолжаются, рекомендуется:
1. Включить режим отладки
2. Проверить токен бота и привязку домена
3. Обратиться к логам для детального анализа
