class CreateStatBotQueries < ActiveRecord::Migration[6.1]
  def change
    create_table :stat_bot_queries do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.text :question

      t.timestamps
    end

    add_index :stat_bot_queries, [:user_id, :created_at]
  end
end
