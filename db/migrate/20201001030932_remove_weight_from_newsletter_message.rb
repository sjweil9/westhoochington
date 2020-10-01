class RemoveWeightFromNewsletterMessage < ActiveRecord::Migration[5.2]
  def change
    remove_column :newsletter_messages, :weight, :string
  end
end
