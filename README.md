# Telegram OAuth Login Plugin

This plugin adds support for logging in via Telegram to your Discourse forum.

## Features

- 🔐 Secure OAuth authentication via Telegram
- 🌐 Multi-language support (English, Russian)
- 👥 Account linking for existing users
- 📱 Mobile-friendly Telegram widget
- 🛡️ Enhanced security with CSRF protection

## Installation

1. Add this plugin to your Discourse installation:
   ```bash
   cd /var/discourse
   ./launcher enter app
   git clone https://github.com/mjsir911/discourse-telegram-auth.git plugins/discourse-telegram-auth
   ```

2. Rebuild your Discourse container:
   ```bash
   ./launcher rebuild app
   ```

## Configuration

### 1. Create a Telegram Bot

1. Start a chat with [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` command
3. Follow the instructions to create your bot
4. Save the **bot token** (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
5. Note your **bot username** (must end with 'Bot' or 'bot')

### 2. Configure Discourse Settings

Go to your Discourse Admin Panel → Settings → Login and configure:

- **telegram_auth_enabled**: Enable Telegram authentication
- **telegram_auth_bot_name**: Your bot's username (e.g., `MyForumBot`)
- **telegram_auth_bot_token**: Your bot's token from BotFather

### 3. Set up Telegram Login Widget

Configure your bot for login widget:
1. Send `/setdomain` to [@BotFather](https://t.me/BotFather)
2. Choose your bot
3. Send your forum's domain (e.g., `forum.example.com`)

## Security

- Bot tokens are stored securely in Discourse settings
- CSRF protection is enabled by default
- Strict validation of bot names and tokens
- Content Security Policy configured for Telegram widgets

## Supported Languages

- English (en)
- Russian (ru)

## Version History

- **v1.1.0** - Enhanced security, better UX, Russian localization
- **v1.0.0** - Initial release

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- [GitHub Issues](https://github.com/mjsir911/discourse-telegram-auth/issues)
- [Discourse Meta](https://meta.discourse.org)
