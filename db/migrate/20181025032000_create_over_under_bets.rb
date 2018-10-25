class CreateOverUnderBets < ActiveRecord::Migration[5.2]
  def change
    create_table :over_under_bets do |t|
      t.boolean :over
      t.references :user, foreign_key: true
      t.references :over_under, foreign_key: true
      t.boolean :completed
      t.boolean :correct

      t.timestamps
    end
  end
end
