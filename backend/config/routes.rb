Rails.application.routes.draw do
  # 1. API for the React Frontend
  namespace :api do
    namespace :v1 do
      resources :products
      resources :orders, only: [:index, :show, :update]
      resources :shops, only: [:show, :update]
    end
  end

  # 2. Webhooks for Telegram and Chapa Payments
  scope :webhooks do
    post 'telegram', to: 'webhooks/telegram#callback'
    post 'chapa', to: 'webhooks/chapa#verify'
  end
end