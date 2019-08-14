class CreatePodcasts < ActiveRecord::Migration[5.2]
  def change
    create_table :podcasts do |t|
      t.references :user, foreign_key: true
      t.integer :week
      t.integer :year
      t.text :file_path

      t.timestamps
    end
  end
end
