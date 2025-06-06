# frozen_string_literal: true

# name: discourse-telegram-auth
# about: Enable Login via Telegram
# version: 1.1.0
# authors: Marco Sirabella
# url: https://github.com/mjsir911/discourse-telegram-auth

gem 'omniauth-telegram', '0.2.1', require: false

enabled_site_setting :telegram_auth_enabled

register_svg_icon "fab-telegram"

extend_content_security_policy script_src: ['https://telegram.org/js/telegram-widget.js']

require "omniauth/telegram"

class ::TelegramAuthenticator < ::Auth::ManagedAuthenticator
  def name
    "telegram"
  end

  def enabled?
    SiteSetting.telegram_auth_enabled
  end

  def can_revoke?
    true
  end

  def can_connect_existing_user?
    true
  end
  def register_middleware(omniauth)
    omniauth.provider :telegram,
           setup: lambda { |env|
             strategy = env["omniauth.strategy"]
             strategy.options[:bot_name] = SiteSetting.telegram_auth_bot_name
             strategy.options[:bot_secret] = SiteSetting.telegram_auth_bot_token
             
             # Добавляем дополнительные опции для улучшенной безопасности
             strategy.options[:button_config] = {
               'size' => 'large',
               'corner-radius' => '20',
               'request-access' => 'write'
             }
           }
  end

  # Исправленная сигнатура метода description_for_user
  def description_for_user(user)
    return "" unless user.present?
    
    begin
      account = user.user_associated_accounts&.find_by(provider_name: name)
      return "" unless account&.info.present?
      
      username = account.info["username"] || account.info["first_name"] || account.uid
      return "" unless username.present?
      
      I18n.t("login.telegram.description", username: username)
    rescue => e
      Rails.logger.warn("TelegramAuthenticator: Error getting description for user #{user.id}: #{e.message}")
      ""
    end
  end

  # Добавляем метод для получения иконки провайдера
  def icon
    "fab-telegram"
  end
  # Переопределяем метод для правильной обработки данных Telegram
  def after_authenticate(auth_token, existing_account = nil)
    # Дополнительная валидация данных от Telegram для предотвращения signature mismatch
    if auth_token[:uid].blank? || auth_token[:provider] != 'telegram'
      Rails.logger.error("TelegramAuthenticator: Invalid auth_token structure")
      return Auth::Result.new.tap { |r| r.failed = true; r.failed_reason = "Invalid authentication data" }
    end

    # Проверяем обязательные поля от Telegram
    required_fields = ['id', 'auth_date']
    telegram_data = auth_token[:extra][:raw_info] || auth_token[:info] || {}
    
    missing_fields = required_fields.select { |field| telegram_data[field].blank? }
    if missing_fields.any?
      Rails.logger.error("TelegramAuthenticator: Missing required fields: #{missing_fields.join(', ')}")
      return Auth::Result.new.tap { |r| r.failed = true; r.failed_reason = "Missing required authentication fields" }
    end

    # Проверяем актуальность данных (не старше 24 часов)
    auth_date = telegram_data['auth_date'].to_i
    if (Time.now.to_i - auth_date) > 86400
      Rails.logger.warn("TelegramAuthenticator: Authentication data is too old")
      return Auth::Result.new.tap { |r| r.failed = true; r.failed_reason = "Authentication session expired" }
    end

    # Убеждаемся, что данные от Telegram корректны
    result = super(auth_token, existing_account)
    
    if result.user && auth_token[:info]
      # Сохраняем дополнительные данные от Telegram с валидацией
      extra_data = {
        telegram_id: auth_token[:uid],
        username: auth_token[:info][:username],
        first_name: auth_token[:info][:first_name],
        last_name: auth_token[:info][:last_name],
        photo_url: auth_token[:info][:image],
        auth_date: auth_date
      }.compact
      
      # Логируем для отладки если включен debug режим
      if SiteSetting.telegram_auth_debug
        Rails.logger.info("TelegramAuthenticator: Successful auth for user #{result.user.id}, telegram_id: #{extra_data[:telegram_id]}")
      end
      
      result.extra_data = extra_data
    end
    
    result
  rescue => e
    Rails.logger.error("TelegramAuthenticator: Error in after_authenticate: #{e.message}")
    Rails.logger.error("TelegramAuthenticator: Backtrace: #{e.backtrace.join("\n")}")
    
    # Возвращаем неудачный результат вместо пропуска ошибки
    Auth::Result.new.tap { |r| r.failed = true; r.failed_reason = "Authentication processing error" }
  end

  # Добавляем дополнительный метод для проверки подписи Telegram
  def validate_telegram_signature(params, bot_token)
    return false if params.blank? || bot_token.blank?
    
    begin
      # Извлекаем хеш из параметров
      received_hash = params['hash']
      return false if received_hash.blank?
      
      # Удаляем хеш из параметров для проверки
      check_params = params.except('hash')
      
      # Создаем секретный ключ
      secret_key = OpenSSL::Digest::SHA256.digest(bot_token)
      
      # Создаем строку для проверки подписи согласно документации Telegram
      hash_fields = %w[auth_date first_name id last_name photo_url username]
      data_check_string = hash_fields
        .select { |field| check_params[field].present? }
        .sort
        .map { |field| "#{field}=#{check_params[field]}" }
        .join("\n")
      
      # Вычисляем HMAC-SHA256
      calculated_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret_key, data_check_string)
      
      # Логируем для отладки если включен debug режим
      if SiteSetting.telegram_auth_debug
        Rails.logger.info("TelegramAuth: Data check string: #{data_check_string}")
        Rails.logger.info("TelegramAuth: Received hash: #{received_hash}")
        Rails.logger.info("TelegramAuth: Calculated hash: #{calculated_hash}")
      end
      
      # Сравниваем хеши
      received_hash == calculated_hash
    rescue => e
      Rails.logger.error("TelegramAuthenticator: Error validating signature: #{e.message}")
      false
    end
  end

  # Проверяем совместимость с различными версиями Discourse
  def self.discourse_compatibility
    return @discourse_compatibility if defined?(@discourse_compatibility)
    
    @discourse_compatibility = {
      has_user_associated_accounts: defined?(UserAssociatedAccount),
      omniauth_version: Gem.loaded_specs['omniauth']&.version&.to_s,
      telegram_gem_version: Gem.loaded_specs['omniauth-telegram']&.version&.to_s
    }
  end

end

auth_provider authenticator: ::TelegramAuthenticator.new,
              icon: "fab-telegram"
