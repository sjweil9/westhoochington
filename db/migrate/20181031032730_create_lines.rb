class CreateLines < ActiveRecord::Migration[5.2]
  def change
    create_table :lines do |t|
      t.references :over_under, foreign_key: true
      t.references :user, foreign_key: true
      t.string :value

      t.timestamps
    end
  end
end
