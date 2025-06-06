// Принудительная регистрация переводов для Telegram Auth
// filepath: assets/javascripts/discourse/initializers/telegram-auth-translations.js

import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "telegram-auth-translations",
  
  initialize() {
    withPluginApi("0.8.31", api => {
      // Регистрируем переводы для кнопок связанных аккаунтов
      const translations = {
        "user.associated_accounts.connect": "Подключить",
        "user.associated_accounts.disconnect": "Отключить",
        "user.associated_accounts.revoke": "Отключить",
        "user.associated_accounts.confirm_revoke": "Отключить этот аккаунт?",
        "user.associated_accounts.not_connected": "Не подключен",
        "user.preferences.account.connect": "Подключить",
        "user.preferences.account.revoke": "Отключить"
      };
      
      // Применяем переводы к I18n
      Object.keys(translations).forEach(key => {
        I18n.translations.ru = I18n.translations.ru || {};
        
        const keys = key.split('.');
        let current = I18n.translations.ru;
        
        for (let i = 0; i < keys.length - 1; i++) {
          current[keys[i]] = current[keys[i]] || {};
          current = current[keys[i]];
        }
        
        current[keys[keys.length - 1]] = translations[key];
      });
      
      console.log("TelegramAuth: Russian translations registered");
    });
  }
};
