class CreateOverUnders < ActiveRecord::Migration[5.2]
  def change
    create_table :over_unders do |t|
      t.string :line
      t.datetime :completed_date
      t.references :user, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end
