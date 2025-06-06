#!/usr/bin/env ruby
# frozen_string_literal: true

require 'openssl'

# Тест проверки подписи согласно документации Telegram
# https://core.telegram.org/widgets/login

class TelegramSignatureChecker
  HASH_FIELDS = %w[auth_date first_name id last_name photo_url username].freeze

  def self.calculate_signature(bot_token, params)
    # Создаем секретный ключ из токена бота (SHA256 hash)
    secret_key = OpenSSL::Digest::SHA256.digest(bot_token)
    
    # Генерируем строку для проверки подписи
    data_check_string = generate_comparison_string(params)
    
    # Создаем HMAC-SHA256 подпись
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret_key, data_check_string)
  end

  def self.generate_comparison_string(params)
    # Фильтруем только нужные поля и сортируем их по алфавиту
    (params.keys & HASH_FIELDS).sort.map { |field| "#{field}=#{params[field]}" }.join("\n")
  end

  def self.verify_signature(bot_token, params)
    received_hash = params['hash']
    calculated_hash = calculate_signature(bot_token, params)
    
    puts "Received hash: #{received_hash}"
    puts "Calculated hash: #{calculated_hash}"
    puts "Data check string: #{generate_comparison_string(params)}"
    puts "Match: #{received_hash == calculated_hash}"
    
    received_hash == calculated_hash
  end
end

# Тестовые данные
test_params = {
  'id' => '123456789',
  'first_name' => 'John',
  'last_name' => 'Doe',
  'username' => 'johndoe',
  'photo_url' => 'https://t.me/i/userpic/320/example.jpg',
  'auth_date' => Time.now.to_i.to_s
}

# Фиктивный токен бота для тестирования
bot_token = '123456789:ABCdefGHIjklMNOpqrsTUVwxyz'

# Генерируем подпись
signature = TelegramSignatureChecker.calculate_signature(bot_token, test_params)
test_params['hash'] = signature

puts "=== Тест проверки подписи Telegram ==="
puts "Параметры: #{test_params}"
puts "=" * 50

TelegramSignatureChecker.verify_signature(bot_token, test_params)

puts "\n=== Тест с неправильным токеном ==="
wrong_token = '987654321:WRONGdefGHIjklMNOpqrsTUVwxyz'
TelegramSignatureChecker.verify_signature(wrong_token, test_params)
