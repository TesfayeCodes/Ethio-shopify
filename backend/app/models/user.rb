class User < ApplicationRecord
  extend Devise::Models
  include DeviseTokenAuth::Concerns::User

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable

  validates :telegram_id, uniqueness: true, allow_nil: true

  def seller_payload
    {
      id: id,
      email: email,
      name: name
    }
  end
end
