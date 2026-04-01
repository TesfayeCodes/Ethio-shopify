class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.string :telegram_user_id
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end
  end
end
