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

ActiveRecord::Schema.define(version: 2022_09_28_141056) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "additional_document_validation_requests", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.string "state", null: false
    t.string "document_request_type"
    t.string "document_request_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sequence"
    t.date "notified_at"
    t.text "cancel_reason"
    t.datetime "cancelled_at"
    t.boolean "post_validation", default: false, null: false
    t.index ["planning_application_id"], name: "index_document_create_requests_on_planning_application_id"
    t.index ["user_id"], name: "index_document_create_requests_on_user_id"
  end

  create_table "api_users", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "token", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "assessment_details", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.text "entry"
    t.string "status", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "category", null: false
    t.index ["planning_application_id"], name: "ix_assessment_details_on_planning_application_id"
    t.index ["user_id"], name: "ix_assessment_details_on_user_id"
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
    t.boolean "automated_activity", default: false, null: false
    t.index ["api_user_id"], name: "index_audits_on_api_user_id"
    t.index ["planning_application_id"], name: "index_audits_on_planning_application_id"
    t.index ["user_id"], name: "index_audits_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "text", null: false
    t.bigint "user_id"
    t.bigint "policy_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["policy_id"], name: "ix_comments_on_policy_id"
    t.index ["user_id"], name: "ix_comments_on_user_id"
  end

  create_table "consistency_checklists", force: :cascade do |t|
    t.integer "status", null: false
    t.integer "description_matches_documents", null: false
    t.integer "documents_consistent", null: false
    t.integer "proposal_details_match_documents", null: false
    t.text "proposal_details_match_documents_comment"
    t.bigint "planning_application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["planning_application_id"], name: "ix_consistency_checklists_on_planning_application_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "description_change_validation_requests", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.string "state", null: false
    t.text "proposed_description"
    t.boolean "approved"
    t.string "rejection_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "previous_description"
    t.integer "sequence"
    t.date "notified_at"
    t.text "cancel_reason"
    t.datetime "cancelled_at"
    t.boolean "auto_closed", default: false
    t.boolean "post_validation", default: false, null: false
    t.datetime "auto_closed_at"
    t.index ["planning_application_id"], name: "index_description_change_requests_on_planning_application_id"
    t.index ["user_id"], name: "index_description_change_requests_on_user_id"
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
    t.boolean "validated"
    t.text "invalidated_document_reason"
    t.text "applicant_description"
    t.bigint "user_id"
    t.bigint "api_user_id"
    t.datetime "received_at"
    t.bigint "additional_document_validation_request_id"
    t.bigint "replacement_document_validation_request_id"
    t.index ["additional_document_validation_request_id"], name: "ix_documents_on_additional_document_validation_request_id"
    t.index ["api_user_id"], name: "ix_documents_on_api_user_id"
    t.index ["planning_application_id"], name: "index_documents_on_planning_application_id"
    t.index ["replacement_document_validation_request_id"], name: "ix_documents_on_replacement_document_validation_request_id"
    t.index ["user_id"], name: "ix_documents_on_user_id"
  end

  create_table "local_authorities", force: :cascade do |t|
    t.string "subdomain", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "signatory_name", null: false
    t.string "signatory_job_title", null: false
    t.text "enquiries_paragraph", null: false
    t.string "email_address", null: false
    t.string "reply_to_notify_id"
    t.string "feedback_email", null: false
    t.string "reviewer_group_email"
    t.index ["subdomain"], name: "index_local_authorities_on_subdomain", unique: true
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.text "entry", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["planning_application_id"], name: "ix_notes_on_planning_application_id"
    t.index ["user_id"], name: "ix_notes_on_user_id"
  end

  create_table "other_change_validation_requests", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.string "state", null: false
    t.text "summary"
    t.text "suggestion"
    t.text "response"
    t.integer "sequence"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "notified_at"
    t.text "cancel_reason"
    t.datetime "cancelled_at"
    t.boolean "fee_item", default: false
    t.boolean "post_validation", default: false, null: false
    t.index ["planning_application_id"], name: "ix_other_change_validation_requests_on_planning_application_id"
    t.index ["user_id"], name: "ix_other_change_validation_requests_on_user_id"
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
    t.text "closed_or_cancellation_comment"
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
    t.string "change_access_id"
    t.date "expiry_date"
    t.decimal "payment_amount", precision: 10, scale: 2
    t.string "result_flag"
    t.text "result_heading"
    t.text "result_description"
    t.string "result_override"
    t.bigint "api_user_id"
    t.bigint "boundary_created_by_id"
    t.jsonb "policy_classes_bak", default: [], array: true
    t.datetime "assessment_in_progress_at"
    t.string "ward"
    t.string "ward_type"
    t.string "latitude"
    t.string "longitude"
    t.datetime "closed_at"
    t.jsonb "planx_data"
    t.datetime "determination_date"
    t.integer "user_role"
    t.boolean "updated_address_or_boundary_geojson", default: false
    t.boolean "constraints_checked", default: false, null: false
    t.boolean "valid_fee"
    t.boolean "documents_missing"
    t.boolean "valid_red_line_boundary"
    t.decimal "invalid_payment_amount", precision: 10, scale: 2
    t.bigint "application_number", null: false
    t.string "parish_name"
    t.jsonb "feedback", default: {}
    t.string "reference"
    t.datetime "validated_at"
    t.datetime "received_at"
    t.index "lower((reference)::text)", name: "ix_planning_applications_on_lower_reference"
    t.index "to_tsvector('english'::regconfig, description)", name: "index_planning_applications_on_description", using: :gin
    t.index ["api_user_id"], name: "ix_planning_applications_on_api_user_id"
    t.index ["application_number", "local_authority_id"], name: "ix_planning_applications_on_application_number__local_authority", unique: true
    t.index ["boundary_created_by_id"], name: "ix_planning_applications_on_boundary_created_by_id"
    t.index ["local_authority_id"], name: "index_planning_applications_on_local_authority_id"
    t.index ["reference", "local_authority_id"], name: "ix_planning_applications_on_reference__local_authority_id", unique: true
    t.index ["user_id"], name: "index_planning_applications_on_user_id"
  end

  create_table "policies", force: :cascade do |t|
    t.string "section", null: false
    t.string "description", null: false
    t.integer "status", null: false
    t.bigint "policy_class_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["policy_class_id"], name: "ix_policies_on_policy_class_id"
  end

  create_table "policy_classes", force: :cascade do |t|
    t.string "schedule", null: false
    t.integer "part", null: false
    t.string "section", null: false
    t.string "url"
    t.string "name", null: false
    t.bigint "planning_application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status", null: false
    t.index ["planning_application_id"], name: "ix_policy_classes_on_planning_application_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "assessor_id"
    t.bigint "reviewer_id"
    t.text "assessor_comment"
    t.text "reviewer_comment"
    t.datetime "reviewed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "challenged"
    t.boolean "submitted"
    t.index ["assessor_id"], name: "index_recommendations_on_assessor_id"
    t.index ["planning_application_id"], name: "index_recommendations_on_planning_application_id"
    t.index ["reviewer_id"], name: "index_recommendations_on_reviewer_id"
  end

  create_table "red_line_boundary_change_validation_requests", force: :cascade do |t|
    t.integer "planning_application_id", null: false
    t.integer "user_id", null: false
    t.string "state", null: false
    t.json "new_geojson", null: false
    t.string "reason", null: false
    t.string "rejection_reason"
    t.boolean "approved"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sequence"
    t.date "notified_at"
    t.text "cancel_reason"
    t.datetime "cancelled_at"
    t.json "original_geojson"
    t.boolean "post_validation", default: false, null: false
    t.boolean "auto_closed", default: false, null: false
    t.datetime "auto_closed_at"
  end

  create_table "replacement_document_validation_requests", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.bigint "old_document_id", null: false
    t.bigint "new_document_id"
    t.string "state", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sequence"
    t.date "notified_at"
    t.text "cancel_reason"
    t.datetime "cancelled_at"
    t.text "reason"
    t.boolean "post_validation", default: false, null: false
    t.index ["new_document_id"], name: "index_document_change_requests_on_new_document_id"
    t.index ["old_document_id"], name: "index_document_change_requests_on_old_document_id"
    t.index ["planning_application_id"], name: "index_document_change_requests_on_planning_application_id"
    t.index ["user_id"], name: "index_document_change_requests_on_user_id"
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
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: true, null: false
    t.string "mobile_number"
    t.integer "otp_delivery_method", default: 0
    t.index ["email", "local_authority_id"], name: "index_users_on_email_and_local_authority_id", unique: true
    t.index ["encrypted_otp_secret"], name: "ix_users_on_encrypted_otp_secret", unique: true
    t.index ["local_authority_id"], name: "index_users_on_local_authority_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "validation_requests", force: :cascade do |t|
    t.bigint "requestable_id", null: false
    t.string "requestable_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "planning_application_id"
    t.datetime "closed_at"
    t.boolean "update_counter", default: false, null: false
    t.index ["planning_application_id"], name: "ix_validation_requests_on_planning_application_id"
    t.index ["requestable_type", "requestable_id"], name: "ix_validation_requests_on_requestable_type__requestable_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "additional_document_validation_requests", "planning_applications"
  add_foreign_key "additional_document_validation_requests", "users"
  add_foreign_key "assessment_details", "planning_applications"
  add_foreign_key "assessment_details", "users"
  add_foreign_key "audits", "api_users"
  add_foreign_key "audits", "planning_applications"
  add_foreign_key "audits", "users"
  add_foreign_key "description_change_validation_requests", "planning_applications"
  add_foreign_key "description_change_validation_requests", "users"
  add_foreign_key "documents", "additional_document_validation_requests"
  add_foreign_key "documents", "api_users"
  add_foreign_key "documents", "replacement_document_validation_requests"
  add_foreign_key "documents", "users"
  add_foreign_key "notes", "planning_applications"
  add_foreign_key "notes", "users"
  add_foreign_key "other_change_validation_requests", "planning_applications"
  add_foreign_key "other_change_validation_requests", "users"
  add_foreign_key "planning_applications", "api_users"
  add_foreign_key "planning_applications", "users"
  add_foreign_key "planning_applications", "users", column: "boundary_created_by_id"
  add_foreign_key "recommendations", "planning_applications"
  add_foreign_key "recommendations", "users", column: "assessor_id"
  add_foreign_key "recommendations", "users", column: "reviewer_id"
  add_foreign_key "replacement_document_validation_requests", "documents", column: "new_document_id"
  add_foreign_key "replacement_document_validation_requests", "documents", column: "old_document_id"
  add_foreign_key "replacement_document_validation_requests", "planning_applications"
  add_foreign_key "replacement_document_validation_requests", "users"
  add_foreign_key "validation_requests", "planning_applications"
end
