#!/usr/bin/env ruby
# Диагностика проблем с Telegram аутентификацией

puts "=== Диагностика Telegram Auth ==="

# Проверяем настройки
puts "\n1. Проверка настроек в settings.yml:"

settings_content = File.read('config/settings.yml')
puts settings_content

puts "\n2. Проверка Content Security Policy:"
plugin_content = File.read('plugin.rb')

if plugin_content.include?("extend_content_security_policy")
  puts "✅ CSP настроен для Telegram виджета"
else
  puts "❌ CSP не настроен"
end

puts "\n3. Проверка зависимостей:"
if plugin_content.include?("omniauth-telegram")
  puts "✅ Зависимость omniauth-telegram найдена"
else
  puts "❌ Зависимость omniauth-telegram не найдена"
end

puts "\n4. Проверка URL структуры:"
puts "Ожидаемый callback URL: https://gig.ovh/auth/telegram/callback"
puts "Текущий запрос URL: https://gig.ovh/auth/telegram?reconnect=true"

puts "\n5. Возможные причины зависания:"
puts "- Неверный токен бота"
puts "- Домен не привязан к боту"
puts "- CSP блокирует загрузку Telegram виджета"
puts "- JavaScript ошибки"
puts "- Неправильная конфигурация middleware"

puts "\n6. Рекомендации для отладки:"
puts "- Проверьте консоль браузера на наличие ошибок JavaScript"
puts "- Убедитесь, что домен gig.ovh привязан к боту через @BotFather"
puts "- Проверьте логи Rails на наличие ошибок"
puts "- Включите telegram_auth_debug в настройках"

puts "\n=== Конец диагностики ==="
