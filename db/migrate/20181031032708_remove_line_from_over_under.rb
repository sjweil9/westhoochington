class RemoveLineFromOverUnder < ActiveRecord::Migration[5.2]
  def change
    remove_column :over_unders, :line, :string
  end
end
