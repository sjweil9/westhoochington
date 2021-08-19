class CreatePayments < ActiveRecord::Migration[5.2]
  def change
    create_table :payments do |t|
      t.references :user, foreign_key: true
      t.string :payment_type
      t.numeric :amount
      t.integer :season_year
      t.integer :week

      t.timestamps
    end
  end
end
