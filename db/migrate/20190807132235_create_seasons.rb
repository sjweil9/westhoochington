class CreateSeasons < ActiveRecord::Migration[5.2]
  def change
    create_table :seasons do |t|
      t.references :user, foreign_key: true
      t.numeric :playoff_rank
      t.numeric :regular_rank

      t.timestamps
    end
  end
end
