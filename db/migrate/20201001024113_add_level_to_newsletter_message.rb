class AddLevelToNewsletterMessage < ActiveRecord::Migration[5.2]
  def change
    add_column :newsletter_messages, :level, :string
  end
end
