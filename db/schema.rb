# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_10_12_184704) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "best_ball_game_players", force: :cascade do |t|
    t.bigint "player_id"
    t.bigint "best_ball_game_id"
    t.decimal "total_points"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "starter"
    t.string "position"
    t.index ["best_ball_game_id"], name: "index_best_ball_game_players_on_best_ball_game_id"
    t.index ["player_id"], name: "index_best_ball_game_players_on_player_id"
  end

  create_table "best_ball_games", force: :cascade do |t|
    t.bigint "best_ball_league_id"
    t.integer "week"
    t.decimal "total_points"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["best_ball_league_id"], name: "index_best_ball_games_on_best_ball_league_id"
    t.index ["user_id"], name: "index_best_ball_games_on_user_id"
  end

  create_table "best_ball_league_users", force: :cascade do |t|
    t.bigint "best_ball_league_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_points"
    t.string "roster_id"
    t.index ["best_ball_league_id"], name: "index_best_ball_league_users_on_best_ball_league_id"
    t.index ["roster_id"], name: "index_best_ball_league_users_on_roster_id"
    t.index ["user_id"], name: "index_best_ball_league_users_on_user_id"
  end

  create_table "best_ball_leagues", force: :cascade do |t|
    t.string "name"
    t.string "sleeper_id"
    t.integer "season_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sleeper_id"], name: "index_best_ball_leagues_on_sleeper_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.bigint "message_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_comments_on_message_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "draft_picks", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "season_year"
    t.string "league_id"
    t.string "league_platform"
    t.string "drafted_league_id"
    t.string "drafted_league_platform"
    t.string "draft_id"
    t.bigint "player_id"
    t.string "draft_type"
    t.integer "overall_pick_number"
    t.integer "round_number"
    t.integer "round_pick_number"
    t.integer "bid_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_draft_picks_on_player_id"
    t.index ["user_id"], name: "index_draft_picks_on_user_id"
  end

  create_table "faab_stats", force: :cascade do |t|
    t.string "season_year"
    t.json "biggest_load"
    t.json "narrowest_fail"
    t.json "biggest_overpay"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "most_impactful"
    t.json "most_impactful_ppg"
    t.json "most_impactful_ppd"
  end

  create_table "game_level_stats", force: :cascade do |t|
    t.json "highest_score"
    t.json "lowest_score"
    t.json "largest_margin"
    t.json "narrowest_margin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "highest_score_espn"
    t.json "highest_score_yahoo"
  end

  create_table "game_side_bet_acceptances", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "game_side_bet_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_side_bet_id"], name: "index_game_side_bet_acceptances_on_game_side_bet_id"
    t.index ["user_id"], name: "index_game_side_bet_acceptances_on_user_id"
  end

  create_table "game_side_bets", force: :cascade do |t|
    t.bigint "game_id"
    t.bigint "user_id"
    t.integer "predicted_winner_id"
    t.string "status"
    t.integer "actual_winner_id"
    t.decimal "amount"
    t.string "odds"
    t.json "possible_acceptances"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "line"
    t.index ["game_id"], name: "index_game_side_bets_on_game_id"
    t.index ["user_id"], name: "index_game_side_bets_on_user_id"
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
    t.boolean "started"
    t.boolean "finished"
    t.boolean "loaded_second_week_data"
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

  create_table "newsletter_messages", force: :cascade do |t|
    t.bigint "user_id"
    t.string "template_string"
    t.string "category"
    t.json "html_content"
    t.integer "used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "level"
    t.index ["user_id"], name: "index_newsletter_messages_on_user_id"
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

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id"
    t.string "payment_type"
    t.decimal "amount"
    t.integer "season_year"
    t.integer "week"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "player_faab_transactions", force: :cascade do |t|
    t.bigint "player_id"
    t.bigint "user_id"
    t.boolean "success"
    t.integer "season_year"
    t.integer "week"
    t.integer "bid_amount"
    t.integer "winning_bid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_player_faab_transactions_on_player_id"
    t.index ["user_id"], name: "index_player_faab_transactions_on_user_id"
  end

  create_table "player_games", force: :cascade do |t|
    t.bigint "player_id"
    t.bigint "user_id"
    t.bigint "game_id"
    t.decimal "points"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "projected_points"
    t.string "lineup_slot"
    t.string "default_lineup_slot"
    t.index ["game_id"], name: "index_player_games_on_game_id"
    t.index ["player_id"], name: "index_player_games_on_player_id"
    t.index ["user_id"], name: "index_player_games_on_user_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "espn_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sleeper_id"
    t.index ["sleeper_id"], name: "index_players_on_sleeper_id"
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

  create_table "season_side_bets", force: :cascade do |t|
    t.integer "season_year"
    t.bigint "user_id"
    t.string "bet_type"
    t.string "status"
    t.json "bet_terms"
    t.decimal "amount"
    t.string "odds"
    t.decimal "line"
    t.string "comparison_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "closing_date"
    t.json "possible_acceptances"
    t.boolean "won"
    t.json "final_bet_results"
    t.index ["user_id"], name: "index_season_side_bets_on_user_id"
  end

  create_table "season_user_stats", force: :cascade do |t|
    t.integer "season_year"
    t.bigint "user_id"
    t.integer "regular_season_place"
    t.json "mir"
    t.integer "weekly_high_scores"
    t.integer "lucky_wins"
    t.integer "unlucky_losses"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "regular_season_wins"
    t.integer "regular_season_losses"
    t.decimal "regular_season_total_points"
    t.integer "total_wins"
    t.integer "total_losses"
    t.decimal "total_points"
    t.decimal "average_projected_points"
    t.decimal "average_points"
    t.json "high_score_weeks"
    t.decimal "average_opponent_points"
    t.decimal "average_margin"
    t.decimal "average_above_projection"
    t.json "lucky_win_weeks"
    t.json "unlucky_loss_weeks"
    t.integer "projected_wins"
    t.integer "wins_above_projection"
    t.json "total_points_per_position"
    t.json "percentage_points_per_position"
    t.index ["user_id"], name: "index_season_user_stats_on_user_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.bigint "user_id"
    t.decimal "playoff_rank"
    t.decimal "regular_rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "season_year"
    t.boolean "finished"
    t.index ["user_id"], name: "index_seasons_on_user_id"
  end

  create_table "side_bet_acceptances", force: :cascade do |t|
    t.string "type"
    t.bigint "user_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bet_type"
    t.integer "side_bet_id"
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

  create_table "user_stats", force: :cascade do |t|
    t.bigint "user_id"
    t.json "mir"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "championships"
    t.json "regular_season_wins"
    t.json "second_place_finishes"
    t.json "playoff_appearances"
    t.decimal "average_finish"
    t.decimal "average_regular_season_finish"
    t.json "playoff_rate"
    t.decimal "average_points_espn"
    t.decimal "average_points_yahoo"
    t.decimal "average_margin"
    t.json "sacko_seasons"
    t.json "lifetime_record"
    t.json "side_bet_results"
    t.json "draft_stats"
    t.json "best_ball_results"
    t.json "schedule_stats"
    t.index ["user_id"], name: "index_user_stats_on_user_id"
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
    t.boolean "podcast_flag"
    t.integer "espn_id"
    t.string "discord_id"
    t.boolean "active"
    t.string "sleeper_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["sleeper_id"], name: "index_users_on_sleeper_id"
  end

  create_table "weekly_side_bets", force: :cascade do |t|
    t.string "comparison_type"
    t.json "bet_terms"
    t.integer "season_year"
    t.integer "week"
    t.bigint "user_id"
    t.string "status"
    t.decimal "amount"
    t.string "odds"
    t.decimal "line"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "possible_acceptances"
    t.boolean "won"
    t.json "final_bet_results"
    t.index ["user_id"], name: "index_weekly_side_bets_on_user_id"
  end

  add_foreign_key "best_ball_game_players", "best_ball_games"
  add_foreign_key "best_ball_game_players", "players"
  add_foreign_key "best_ball_games", "best_ball_leagues"
  add_foreign_key "best_ball_games", "users"
  add_foreign_key "best_ball_league_users", "best_ball_leagues"
  add_foreign_key "best_ball_league_users", "users"
  add_foreign_key "comments", "messages"
  add_foreign_key "comments", "users"
  add_foreign_key "draft_picks", "players"
  add_foreign_key "draft_picks", "users"
  add_foreign_key "game_side_bet_acceptances", "game_side_bets"
  add_foreign_key "game_side_bet_acceptances", "users"
  add_foreign_key "game_side_bets", "games"
  add_foreign_key "game_side_bets", "users"
  add_foreign_key "games", "users"
  add_foreign_key "lines", "over_unders"
  add_foreign_key "lines", "users"
  add_foreign_key "messages", "users"
  add_foreign_key "newsletter_messages", "users"
  add_foreign_key "nickname_votes", "nicknames"
  add_foreign_key "nickname_votes", "users"
  add_foreign_key "nicknames", "users"
  add_foreign_key "over_under_bets", "lines"
  add_foreign_key "over_under_bets", "users"
  add_foreign_key "over_unders", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "player_faab_transactions", "players"
  add_foreign_key "player_faab_transactions", "users"
  add_foreign_key "player_games", "games"
  add_foreign_key "player_games", "players"
  add_foreign_key "player_games", "users"
  add_foreign_key "podcasts", "users"
  add_foreign_key "season_side_bets", "users"
  add_foreign_key "season_user_stats", "users"
  add_foreign_key "seasons", "users"
  add_foreign_key "side_bet_acceptances", "users"
  add_foreign_key "side_bets", "users"
  add_foreign_key "user_stats", "users"
  add_foreign_key "weekly_side_bets", "users"
end
