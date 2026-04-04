module Telegram
  class MessageSender
    def initialize(telegram_service: TelegramService.new)
      @telegram_service = telegram_service
    end

    def call(chat_id:, text:, reply_markup: nil)
      @telegram_service.send_message(chat_id:, text:, reply_markup:)
    end
  end
end
