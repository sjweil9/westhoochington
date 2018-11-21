class CreateNicknameVotes < ActiveRecord::Migration[5.2]
  def change
    create_table :nickname_votes do |t|
      t.references :user, foreign_key: true
      t.references :nickname, foreign_key: true
      t.numeric :value

      t.timestamps
    end
  end
end
