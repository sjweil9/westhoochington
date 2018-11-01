class CreateSideBets < ActiveRecord::Migration[5.2]
  def change
    create_table :side_bets do |t|
      t.numeric :amount
      t.text :terms
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
