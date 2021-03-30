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

ActiveRecord::Schema.define(version: 2021_03_30_100534) do

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
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_users", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "token", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id"
    t.string "activity_type", null: false
    t.string "activity_information"
    t.string "audit_comment"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "api_user_id"
    t.index ["api_user_id"], name: "index_audits_on_api_user_id"
    t.index ["planning_application_id"], name: "index_audits_on_planning_application_id"
    t.index ["user_id"], name: "index_audits_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "archived_at"
    t.string "archive_reason"
    t.jsonb "tags", default: []
    t.string "numbers", default: "", null: false
    t.boolean "publishable", default: false
    t.boolean "referenced_in_decision_notice", default: false
    t.index ["planning_application_id"], name: "index_documents_on_planning_application_id"
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
    t.index ["subdomain"], name: "index_local_authorities_on_subdomain", unique: true
  end

  create_table "planning_applications", force: :cascade do |t|
    t.date "target_date", null: false
    t.integer "application_type", null: false
    t.string "status", default: "not_started", null: false
    t.datetime "started_at"
    t.datetime "determined_at"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.datetime "awaiting_determination_at"
    t.datetime "in_assessment_at"
    t.datetime "awaiting_correction_at"
    t.jsonb "proposal_details"
    t.jsonb "audit_log"
    t.string "agent_first_name"
    t.string "agent_last_name"
    t.string "agent_phone"
    t.string "agent_email"
    t.string "applicant_first_name"
    t.string "applicant_last_name"
    t.string "applicant_email"
    t.string "applicant_phone"
    t.bigint "local_authority_id"
    t.datetime "invalidated_at"
    t.datetime "withdrawn_at"
    t.datetime "returned_at"
    t.string "payment_reference"
    t.text "cancellation_comment"
    t.date "documents_validated_at"
    t.string "work_status", default: "proposed"
    t.string "decision"
    t.text "public_comment"
    t.string "address_1"
    t.string "address_2"
    t.string "town"
    t.string "county"
    t.string "postcode"
    t.string "uprn"
    t.json "boundary_geojson"
    t.text "constraints", default: [], null: false, array: true
    t.index ["local_authority_id"], name: "index_planning_applications_on_local_authority_id"
    t.index ["user_id"], name: "index_planning_applications_on_user_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "assessor_id", null: false
    t.bigint "reviewer_id"
    t.text "assessor_comment"
    t.text "reviewer_comment"
    t.datetime "reviewed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "challenged"
    t.index ["assessor_id"], name: "index_recommendations_on_assessor_id"
    t.index ["planning_application_id"], name: "index_recommendations_on_planning_application_id"
    t.index ["reviewer_id"], name: "index_recommendations_on_reviewer_id"
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
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audits", "api_users"
  add_foreign_key "audits", "planning_applications"
  add_foreign_key "planning_applications", "users"
  add_foreign_key "recommendations", "planning_applications"
  add_foreign_key "recommendations", "users", column: "assessor_id"
  add_foreign_key "recommendations", "users", column: "reviewer_id"
end
