Rails.application.routes.draw do
  mount_devise_token_auth_for "User",
                             at: "auth",
                             controllers: {
                               sessions: "auth/sessions",
                               registrations: "auth/registrations"
                             }

  # 1. API for the React Frontend
  namespace :api do
    namespace :v1 do
      get "seller", to: "sellers#show"
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
