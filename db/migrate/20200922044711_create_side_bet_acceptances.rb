class CreateSideBetAcceptances < ActiveRecord::Migration[5.2]
  def change
    create_table :side_bet_acceptances do |t|
      t.references :side_bet, foreign_key: true
      t.string :type
      t.references :user, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
