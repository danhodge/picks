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

ActiveRecord::Schema.define(version: 2019_12_20_030652) do

  create_table "bowls", force: :cascade do |t|
    t.string "name", null: false
    t.string "city"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_bowls_on_name", unique: true
  end

  create_table "final_scores", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "team_id", null: false
    t.integer "points", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "team_id"], name: "index_final_scores_on_game_id_and_team_id", unique: true
    t.index ["game_id"], name: "index_final_scores_on_game_id"
    t.index ["team_id"], name: "index_final_scores_on_team_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "season_id"
    t.integer "bowl_id"
    t.datetime "game_time", null: false
    t.integer "visiting_team_id"
    t.integer "home_team_id"
    t.float "point_spread"
    t.integer "game_type", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bowl_id"], name: "index_games_on_bowl_id"
    t.index ["home_team_id"], name: "index_games_on_home_team_id"
    t.index ["season_id", "bowl_id"], name: "index_games_on_season_id_and_bowl_id", unique: true
    t.index ["season_id"], name: "index_games_on_season_id"
    t.index ["visiting_team_id"], name: "index_games_on_visiting_team_id"
  end

  create_table "participants", force: :cascade do |t|
    t.integer "season_id"
    t.integer "user_id"
    t.string "nickname", null: false
    t.integer "tiebreaker", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nickname", "season_id"], name: "index_participants_on_nickname_and_season_id", unique: true
    t.index ["season_id"], name: "index_participants_on_season_id"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "picks", force: :cascade do |t|
    t.integer "season_id"
    t.integer "participant_id"
    t.integer "game_id"
    t.integer "team_id"
    t.integer "points", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_picks_on_game_id"
    t.index ["participant_id"], name: "index_picks_on_participant_id"
    t.index ["season_id", "participant_id", "game_id"], name: "index_picks_on_season_id_and_participant_id_and_game_id", unique: true
    t.index ["season_id"], name: "index_picks_on_season_id"
    t.index ["team_id"], name: "index_picks_on_team_id"
  end

  create_table "records", force: :cascade do |t|
    t.integer "season_id"
    t.integer "team_id"
    t.integer "wins", null: false
    t.integer "losses", null: false
    t.integer "ranking"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_scores_on_game_id"
    t.index ["team_id"], name: "index_scores_on_team_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.integer "year", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year"], name: "index_seasons_on_year", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id"
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "uuid", null: false
    t.integer "user_type", default: 1, null: false
    t.string "password"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["token"], name: "index_users_on_token", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

end
