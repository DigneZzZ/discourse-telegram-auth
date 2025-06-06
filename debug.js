// Скрипт для диагностики проблем с Telegram виджетом
// Добавьте этот код в консоль браузера для отладки

console.log("=== Telegram Widget Diagnostics ===");

// Проверяем загрузку Telegram скрипта
if (window.TelegramLoginWidget) {
    console.log("✅ Telegram widget script loaded");
} else {
    console.log("❌ Telegram widget script NOT loaded");
}

// Проверяем наличие виджета на странице
const telegramScript = document.querySelector('script[src*="telegram-widget.js"]');
if (telegramScript) {
    console.log("✅ Telegram widget script found in DOM");
    console.log("Script src:", telegramScript.src);
} else {
    console.log("❌ Telegram widget script NOT found in DOM");
}

// Проверяем параметры виджета
const telegramWidgets = document.querySelectorAll('[data-telegram-login]');
console.log("Telegram widgets found:", telegramWidgets.length);

telegramWidgets.forEach((widget, index) => {
    console.log(`Widget ${index + 1}:`);
    console.log("  Bot name:", widget.getAttribute('data-telegram-login'));
    console.log("  Auth URL:", widget.getAttribute('data-auth-url'));
    console.log("  Size:", widget.getAttribute('data-size'));
    console.log("  Corner radius:", widget.getAttribute('data-corner-radius'));
    console.log("  Request access:", widget.getAttribute('data-request-access'));
});

// Проверяем CSP ошибки
const cspErrors = [];
const originalLog = console.error;
console.error = function(...args) {
    if (args.some(arg => typeof arg === 'string' && arg.includes('Content Security Policy'))) {
        cspErrors.push(args.join(' '));
    }
    originalLog.apply(console, args);
};

// Проверяем сетевые ошибки
fetch('https://telegram.org/js/telegram-widget.js?4')
    .then(response => {
        if (response.ok) {
            console.log("✅ Telegram widget script accessible");
        } else {
            console.log("❌ Telegram widget script request failed:", response.status);
        }
    })
    .catch(error => {
        console.log("❌ Network error loading Telegram script:", error);
    });

// Выводим рекомендации
setTimeout(() => {
    console.log("\n=== Recommendations ===");
    
    if (cspErrors.length > 0) {
        console.log("❌ CSP errors detected:");
        cspErrors.forEach(error => console.log("  ", error));
        console.log("Solution: Check Content Security Policy settings");
    }
    
    if (telegramWidgets.length === 0) {
        console.log("❌ No Telegram widgets found");
        console.log("Solution: Check if plugin is properly configured and enabled");
    }
    
    if (!window.TelegramLoginWidget && telegramScript) {
        console.log("❌ Script loaded but widget not initialized");
        console.log("Solution: Check for JavaScript errors or CSP blocking");
    }
    
    console.log("\nFor more help, check:");
    console.log("1. Browser console for JavaScript errors");
    console.log("2. Network tab for failed requests");
    console.log("3. Rails logs for authentication errors");
    console.log("4. Bot configuration in @BotFather");
}, 2000);

console.log("=== End Diagnostics ===");
