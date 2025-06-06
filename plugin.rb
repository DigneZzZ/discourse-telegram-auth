# frozen_string_literal: true

# name: discourse-telegram-auth
# about: Enable Login via Telegram
# version: 1.1.4
# authors: Marco Sirabella
# url: https://github.com/mjsir911/discourse-telegram-auth
# Fixed: Content Security Policy issues, Telegram widget loading, and Russian translations

gem 'omniauth-telegram', '0.2.1', require: false

enabled_site_setting :telegram_auth_enabled

register_svg_icon "fab-telegram"

# Расширенная CSP конфигурация для Telegram виджета
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
  connect_src: [
    'https://telegram.org',
    'https://*.telegram.org',
    'https://oauth.telegram.org'
  ],
  frame_src: [
    'https://oauth.telegram.org',
    'https://telegram.org'
  ],
  child_src: [
    'https://oauth.telegram.org',
    'https://telegram.org'
  ]
)

require_dependency 'omniauth/telegram'

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
             
             # Логируем для отладки
             Rails.logger.info("TelegramAuth: Setting up strategy") if SiteSetting.telegram_auth_debug
             
             strategy.options[:bot_name] = SiteSetting.telegram_auth_bot_name
             strategy.options[:bot_secret] = SiteSetting.telegram_auth_bot_token
             
             # Проверяем настройки
             if SiteSetting.telegram_auth_bot_name.blank?
               Rails.logger.error("TelegramAuth: Bot name is not configured")
               raise "Telegram bot name is required"
             end
             
             if SiteSetting.telegram_auth_bot_token.blank?
               Rails.logger.error("TelegramAuth: Bot token is not configured")
               raise "Telegram bot token is required"
             end
             
             Rails.logger.info("TelegramAuth: Bot name: #{SiteSetting.telegram_auth_bot_name}") if SiteSetting.telegram_auth_debug
             
             # Добавляем дополнительные опции для улучшенной безопасности
             strategy.options[:button_config] = {
               'size' => 'large',
               'corner-radius' => '20',
               'request-access' => 'write'
             }
           }
  rescue => e
    Rails.logger.error("TelegramAuth: Error in register_middleware: #{e.message}")
    Rails.logger.error("TelegramAuth: Backtrace: #{e.backtrace.join("\n")}")
    raise e
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
    end  end
  
  # Добавляем переводы для кнопок подключения
  def self.register_translations
    # Регистрируем переводы для кнопок
    return unless defined?(I18n)
    
    # Добавляем переводы напрямую
    I18n.backend.store_translations(:ru, {
      js: {
        user: {
          associated_accounts: {
            connect: "Подключить",
            disconnect: "Отключить", 
            revoke: "Отключить"
          }
        }
      }
    })
    
    Rails.logger.info("TelegramAuth: Translations registered") if SiteSetting.telegram_auth_debug rescue nil
  end
  
  # Добавляем метод для получения иконки провайдера
  def icon
    "fab-telegram"
  end

  # Переопределяем connect_path для предотвращения генерации reconnect=true
  def connect_path(options = {})
    # Всегда возвращаем путь без reconnect параметра
    "/auth/telegram"
  end

  # Переопределяем revoke_path для корректной работы отключения
  def revoke_path
    "/auth/telegram/revoke"
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

  # Добавляем метод для диагностики проблем с аутентификацией
  def self.diagnose_setup
    Rails.logger.info("=== TelegramAuth Diagnostics ===")
    
    # Проверяем настройки
    enabled = SiteSetting.telegram_auth_enabled
    bot_name = SiteSetting.telegram_auth_bot_name
    bot_token = SiteSetting.telegram_auth_bot_token
    
    Rails.logger.info("Plugin enabled: #{enabled}")
    Rails.logger.info("Bot name configured: #{bot_name.present?}")
    Rails.logger.info("Bot token configured: #{bot_token.present?}")
    
    if bot_name.present?
      Rails.logger.info("Bot name: #{bot_name}")
      Rails.logger.info("Bot name valid format: #{bot_name.match?(/^[a-zA-Z][a-zA-Z0-9_]{3,}[Bb]ot$/)}")
    end
    
    if bot_token.present?
      Rails.logger.info("Bot token format valid: #{bot_token.match?(/^[0-9]{8,10}:[a-zA-Z0-9_-]{35}$/)}")
    end
    
    # Проверяем зависимости
    begin
      require 'omniauth/telegram'
      Rails.logger.info("OmniAuth Telegram gem: Available")
    rescue LoadError => e
      Rails.logger.error("OmniAuth Telegram gem: NOT AVAILABLE - #{e.message}")
    end
    
    Rails.logger.info("=== End Diagnostics ===")
  end

end

auth_provider authenticator: ::TelegramAuthenticator.new,
              icon: "fab-telegram"

# Добавляем обработчик для reconnect параметра
after_initialize do
  # Регистрируем переводы для русского интерфейса
  ::TelegramAuthenticator.register_translations
  
  # Добавляем роуты для обработки Telegram OAuth
  Discourse::Application.routes.append do
    # Основной роут для Telegram auth - показывает виджет
    get '/auth/telegram' => 'telegram_auth#show'
    
    # Роут для callback от Telegram
    get '/auth/telegram/callback' => 'users/omniauth_callbacks#telegram'
    
    # Роут для отключения аккаунта
    delete '/auth/telegram/revoke' => 'users/omniauth_callbacks#telegram_revoke'
  end
  
  # Создаем контроллер для показа Telegram виджета
  class ::TelegramAuthController < ::ApplicationController
    skip_before_action :verify_authenticity_token
    
    def show
      # Проверяем настройки
      unless SiteSetting.telegram_auth_enabled
        return redirect_to '/', alert: 'Telegram authentication is disabled'
      end
      
      unless SiteSetting.telegram_auth_bot_name.present?
        return redirect_to '/', alert: 'Telegram bot is not configured'
      end
      
      # Логируем для отладки
      Rails.logger.info("TelegramAuth: Showing auth page") if SiteSetting.telegram_auth_debug
      
      # Очищаем reconnect параметр если есть
      if params[:reconnect] == 'true'
        Rails.logger.info("TelegramAuth: Removing reconnect parameter") if SiteSetting.telegram_auth_debug
        redirect_to '/auth/telegram' and return
      end
      
      render 'omniauth_callbacks/telegram', layout: false
    end
  end
  
  # Модифицируем существующий контроллер для обработки callbacks
  require_dependency 'users/omniauth_callbacks_controller'
  
  Users::OmniauthCallbacksController.class_eval do
    def telegram
      Rails.logger.info("TelegramAuth: Processing Telegram callback") if SiteSetting.telegram_auth_debug
      
      # Стандартная обработка OmniAuth callback
      authenticator = ::TelegramAuthenticator.new
      auth_result = authenticator.after_authenticate(request.env["omniauth.auth"], existing_account: current_user)
      
      if auth_result.failed?
        Rails.logger.error("TelegramAuth: Authentication failed - #{auth_result.failed_reason}")
        return redirect_to '/', alert: 'Telegram authentication failed'
      end
      
      if auth_result.user
        log_on_user(auth_result.user)
        Rails.logger.info("TelegramAuth: User successfully authenticated") if SiteSetting.telegram_auth_debug
        redirect_to '/', notice: 'Successfully connected to Telegram'
      else
        Rails.logger.error("TelegramAuth: No user in auth result")
        redirect_to '/', alert: 'Authentication error'
      end
    end
    
    def telegram_revoke
      Rails.logger.info("TelegramAuth: Handling revoke request") if SiteSetting.telegram_auth_debug
      
      unless current_user
        Rails.logger.warn("TelegramAuth: Revoke attempted without authenticated user")
        return render json: { error: "Not authenticated" }, status: 401
      end
      
      begin
        # Находим и удаляем связанный аккаунт Telegram
        account = current_user.user_associated_accounts.find_by(provider_name: 'telegram')
        if account
          account.destroy!
          Rails.logger.info("TelegramAuth: Successfully revoked Telegram account for user #{current_user.id}")
          render json: { success: true }
        else
          Rails.logger.warn("TelegramAuth: No Telegram account found for user #{current_user.id}")
          render json: { error: "No Telegram account found" }, status: 404
        end
      rescue => e
        Rails.logger.error("TelegramAuth: Error revoking Telegram account: #{e.message}")
        render json: { error: "Failed to revoke account" }, status: 500
      end
    end
  end
end
