class CreateNewsletterMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :newsletter_messages do |t|
      t.references :user, foreign_key: true
      t.string :template_string
      t.string :category
      t.json :html_content
      t.integer :used
      t.string :weight

      t.timestamps
    end
  end
end
