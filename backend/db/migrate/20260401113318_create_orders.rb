class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :status
      t.decimal :total_price
      t.references :shop, null: false, foreign_key: true
      t.string :telegram_user_id
      t.string :payment_reference

      t.timestamps
    end
  end
end
