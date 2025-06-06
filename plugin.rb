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
           }
  end

  def description_for_user(user)
    return '' unless user&.user_associated_accounts
    
    account = user.user_associated_accounts.find_by(provider_name: 'telegram')
    return '' unless account
    
    I18n.t("login.telegram.description", username: account.info&.dig('username') || account.uid)
  end
end

auth_provider authenticator: ::TelegramAuthenticator.new,
              icon: "fab-telegram"
