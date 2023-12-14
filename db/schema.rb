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

ActiveRecord::Schema[7.0].define(version: 2023_12_14_133541) do
  create_table "bowls", force: :cascade do |t|
    t.string "name", null: false
    t.string "city"
    t.string "state"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_bowls_on_name", unique: true
  end

  create_table "final_scores", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "team_id", null: false
    t.integer "points", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["game_id", "team_id"], name: "index_final_scores_on_game_id_and_team_id", unique: true
    t.index ["game_id"], name: "index_final_scores_on_game_id"
    t.index ["team_id"], name: "index_final_scores_on_team_id"
  end

  create_table "game_changes", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "new_team_id", null: false
    t.integer "previous_visiting_team_id"
    t.integer "previous_home_team_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "status", default: 0, null: false
    t.index ["game_id"], name: "index_game_changes_on_game_id"
    t.index ["new_team_id"], name: "index_game_changes_on_new_team_id"
    t.index ["previous_home_team_id"], name: "index_game_changes_on_previous_home_team_id"
    t.index ["previous_visiting_team_id"], name: "index_game_changes_on_previous_visiting_team_id"
    t.index ["status"], name: "index_game_changes_on_status"
  end

  create_table "games", force: :cascade do |t|
    t.integer "season_id", null: false
    t.integer "bowl_id", null: false
    t.datetime "game_time", precision: nil, null: false
    t.integer "visiting_team_id", null: false
    t.integer "home_team_id", null: false
    t.float "point_spread"
    t.integer "game_type", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "game_status", default: 0, null: false
    t.index ["bowl_id"], name: "index_games_on_bowl_id"
    t.index ["home_team_id"], name: "index_games_on_home_team_id"
    t.index ["season_id", "bowl_id"], name: "index_games_on_season_id_and_bowl_id", unique: true
    t.index ["season_id"], name: "index_games_on_season_id"
    t.index ["visiting_team_id"], name: "index_games_on_visiting_team_id"
  end

  create_table "participants", force: :cascade do |t|
    t.integer "season_id", null: false
    t.integer "user_id"
    t.string "nickname", null: false
    t.integer "tiebreaker", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["nickname", "season_id"], name: "index_participants_on_nickname_and_season_id", unique: true
    t.index ["season_id"], name: "index_participants_on_season_id"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "picks", force: :cascade do |t|
    t.integer "participant_id", null: false
    t.integer "game_id", null: false
    t.integer "team_id", null: false
    t.integer "points", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "status", default: 0, null: false
    t.index ["game_id"], name: "index_picks_on_game_id"
    t.index ["participant_id", "game_id"], name: "index_picks_on_participant_id_and_game_id", unique: true
    t.index ["participant_id"], name: "index_picks_on_participant_id"
    t.index ["status"], name: "index_picks_on_status"
    t.index ["team_id"], name: "index_picks_on_team_id"
  end

  create_table "records", force: :cascade do |t|
    t.integer "season_id", null: false
    t.integer "team_id", null: false
    t.integer "wins", null: false
    t.integer "losses", null: false
    t.integer "ranking"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["season_id", "team_id"], name: "index_records_on_season_id_and_team_id", unique: true
    t.index ["season_id"], name: "index_records_on_season_id"
    t.index ["team_id"], name: "index_records_on_team_id"
  end

  create_table "scores", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "team_id", null: false
    t.integer "points", null: false
    t.integer "quarter", null: false
    t.integer "time_remaining_seconds", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["game_id"], name: "index_scores_on_game_id"
    t.index ["team_id"], name: "index_scores_on_team_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.integer "year", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["year"], name: "index_seasons_on_year", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "source_game_id"
    t.integer "team_type", default: 0, null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
    t.index ["source_game_id"], name: "index_teams_on_source_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "uuid", null: false
    t.integer "user_type", default: 1, null: false
    t.string "password"
    t.string "token"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.string "nickname"
    t.string "phone_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["token"], name: "index_users_on_token", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

end
