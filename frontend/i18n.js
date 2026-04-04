import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

i18n
  .use(LanguageDetector) // Automatically detects if the user's browser is in Amharic
  .use(initReactI18next)
  .init({
    resources: {
      en: {
        translation: {
          "welcome": "Welcome to EthioShopify Admin",
          "sidebar": {
            "dashboard": "Dashboard",
            "products": "Products",
            "orders": "Orders",
            "settings": "Settings"
          },
          "stats": {
            "total_sales": "Total Sales",
            "active_shops": "Active Shops"
          }
        }
      },
      am: {
        translation: {
          "welcome": "እንኳን ወደ ኢትዮ-ሾፒፋይ አስተዳዳሪ በደህና መጡ",
          "sidebar": {
            "dashboard": "ዳሽቦርድ",
            "products": "ምርቶች",
            "orders": "ትዕዛዞች",
            "settings": "ቅንብሮች"
          },
          "stats": {
            "total_sales": "ጠቅላላ ሽያጭ",
            "active_shops": "ንቁ ሱቆች"
          }
        }
      }
    },
    fallbackLng: "en",
    interpolation: {
      escapeValue: false // React already safes from xss
    }
  });

export default i18n;