class CreateSideBetAcceptances < ActiveRecord::Migration[5.2]
  def change
    create_table :side_bet_acceptances do |t|
      t.references :side_bet, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
