class CreateUserStats < ActiveRecord::Migration[5.2]
  def change
    create_table :user_stats do |t|
      t.references :user, foreign_key: true
      t.json :mir

      t.timestamps
    end
  end
end
