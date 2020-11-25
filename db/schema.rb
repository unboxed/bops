# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_25_150405) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "agents", force: :cascade do |t|
    t.string "phone"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "company_name"
    t.string "company_number"
    t.string "address_1"
    t.string "address_2"
    t.string "address_3"
    t.string "town"
    t.string "postcode"
    t.string "country"
    t.string "phone_2"
  end

  create_table "applicants", force: :cascade do |t|
    t.string "phone"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "residence_status", default: false, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "company_name"
    t.string "company_number"
    t.string "address_1"
    t.string "address_2"
    t.string "address_3"
    t.string "town"
    t.string "postcode"
    t.string "country"
    t.string "phone_2"
    t.bigint "agent_id"
    t.index ["agent_id"], name: "index_applicants_on_agent_id"
  end

  create_table "decisions", force: :cascade do |t|
    t.datetime "decided_at"
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status"
    t.text "public_comment"
    t.text "private_comment"
    t.index ["planning_application_id"], name: "index_decisions_on_planning_application_id"
    t.index ["user_id"], name: "index_decisions_on_user_id"
  end

  create_table "drawings", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "archived_at"
    t.integer "archive_reason"
    t.jsonb "tags", default: [], null: false
    t.jsonb "numbers", default: [], null: false
    t.index ["planning_application_id"], name: "index_drawings_on_planning_application_id"
  end

  create_table "local_authorities", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "signatory_name"
    t.string "signatory_job_title"
    t.text "enquiries_paragraph"
    t.string "email_address"
  end

  create_table "planning_applications", force: :cascade do |t|
    t.date "target_date", null: false
    t.integer "application_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "determined_at"
    t.text "description"
    t.bigint "site_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "agent_id"
    t.bigint "applicant_id"
    t.string "ward"
    t.bigint "user_id"
    t.datetime "awaiting_determination_at"
    t.datetime "in_assessment_at"
    t.datetime "awaiting_correction_at"
    t.bigint "local_authority_id"
    t.index ["agent_id"], name: "index_planning_applications_on_agent_id"
    t.index ["applicant_id"], name: "index_planning_applications_on_applicant_id"
    t.index ["local_authority_id"], name: "index_planning_applications_on_local_authority_id"
    t.index ["site_id"], name: "index_planning_applications_on_site_id"
    t.index ["user_id"], name: "index_planning_applications_on_user_id"
  end

  create_table "policy_considerations", force: :cascade do |t|
    t.text "policy_question", null: false
    t.text "applicant_answer", null: false
    t.bigint "policy_evaluation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["policy_evaluation_id"], name: "index_policy_considerations_on_policy_evaluation_id"
  end

  create_table "policy_evaluations", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status", default: 0, null: false
    t.index ["planning_application_id"], name: "index_policy_evaluations_on_planning_application_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "address_1"
    t.string "address_2"
    t.string "town"
    t.string "county"
    t.string "postcode"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "role", default: 0
    t.string "name"
    t.bigint "local_authority_id"
    t.index ["email", "local_authority_id"], name: "index_users_on_email_and_local_authority_id", unique: true
    t.index ["local_authority_id"], name: "index_users_on_local_authority_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "applicants", "agents"
  add_foreign_key "planning_applications", "users"
end
