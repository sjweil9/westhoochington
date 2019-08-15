# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_08_15_010148) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.bigint "message_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_comments_on_message_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "opponent_id"
    t.integer "week"
    t.integer "season_year"
    t.float "active_total"
    t.float "bench_total"
    t.float "projected_total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "opponent_active_total"
    t.float "opponent_projected_total"
    t.float "opponent_bench_total"
    t.index ["user_id"], name: "index_games_on_user_id"
  end

  create_table "lines", force: :cascade do |t|
    t.bigint "over_under_id"
    t.bigint "user_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["over_under_id"], name: "index_lines_on_over_under_id"
    t.index ["user_id"], name: "index_lines_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "nickname_votes", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "nickname_id"
    t.decimal "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nickname_id"], name: "index_nickname_votes_on_nickname_id"
    t.index ["user_id"], name: "index_nickname_votes_on_user_id"
  end

  create_table "nicknames", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_nicknames_on_user_id"
  end

  create_table "over_under_bets", force: :cascade do |t|
    t.boolean "over"
    t.bigint "user_id"
    t.boolean "completed"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "line_id"
    t.index ["line_id"], name: "index_over_under_bets_on_line_id"
    t.index ["user_id"], name: "index_over_under_bets_on_user_id"
  end

  create_table "over_unders", force: :cascade do |t|
    t.datetime "completed_date"
    t.bigint "user_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_over_unders_on_user_id"
  end

  create_table "podcasts", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "week"
    t.integer "year"
    t.text "file_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title"
    t.index ["user_id"], name: "index_podcasts_on_user_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.bigint "user_id"
    t.decimal "playoff_rank"
    t.decimal "regular_rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "season_year"
    t.index ["user_id"], name: "index_seasons_on_user_id"
  end

  create_table "side_bet_acceptances", force: :cascade do |t|
    t.bigint "side_bet_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.boolean "paid"
    t.index ["side_bet_id"], name: "index_side_bet_acceptances_on_side_bet_id"
    t.index ["user_id"], name: "index_side_bet_acceptances_on_user_id"
  end

  create_table "side_bets", force: :cascade do |t|
    t.decimal "amount"
    t.text "terms"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completed"
    t.string "status"
    t.integer "max_takers"
    t.datetime "closing_date"
    t.boolean "paid"
    t.datetime "completed_date"
    t.index ["user_id"], name: "index_side_bets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "newsletter"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "comments", "messages"
  add_foreign_key "comments", "users"
  add_foreign_key "games", "users"
  add_foreign_key "lines", "over_unders"
  add_foreign_key "lines", "users"
  add_foreign_key "messages", "users"
  add_foreign_key "nickname_votes", "nicknames"
  add_foreign_key "nickname_votes", "users"
  add_foreign_key "nicknames", "users"
  add_foreign_key "over_under_bets", "lines"
  add_foreign_key "over_under_bets", "users"
  add_foreign_key "over_unders", "users"
  add_foreign_key "podcasts", "users"
  add_foreign_key "seasons", "users"
  add_foreign_key "side_bet_acceptances", "side_bets"
  add_foreign_key "side_bet_acceptances", "users"
  add_foreign_key "side_bets", "users"
end
