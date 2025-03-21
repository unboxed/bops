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

ActiveRecord::Schema[7.2].define(version: 2025_03_21_121622) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "additional_services", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.bigint "planning_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_additional_services_on_planning_application_id"
  end

  create_table "api_users", force: :cascade do |t|
    t.string "name", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "local_authority_id"
    t.jsonb "file_downloader", default: {"type" => "NoAuthentication"}
    t.string "service"
    t.datetime "revoked_at"
    t.datetime "last_used_at"
    t.index ["local_authority_id", "name"], name: "ix_api_users_on_local_authority_id__name", unique: true, where: "(revoked_at IS NULL)"
    t.index ["local_authority_id", "token"], name: "ix_api_users_on_local_authority_id__token", unique: true
    t.index ["local_authority_id"], name: "ix_api_users_on_local_authority_id"
    t.index ["revoked_at"], name: "ix_api_users_on_revoked_at"
  end

  create_table "appeals", force: :cascade do |t|
    t.text "reason", null: false
    t.string "status", default: "lodged", null: false
    t.string "decision"
    t.datetime "lodged_at", null: false
    t.datetime "validated_at"
    t.datetime "started_at"
    t.datetime "determined_at"
    t.bigint "planning_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_appeals_on_planning_application_id"
  end

  create_table "application_type_configs", force: :cascade do |t|
    t.string "name", null: false
    t.integer "part"
    t.string "section"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assessment_details", array: true
    t.string "steps", default: ["validation", "consultation", "assessment", "review"], array: true
    t.string "consistency_checklist", array: true
    t.jsonb "document_tags", default: {}, null: false
    t.jsonb "features", default: {}
    t.string "status", default: "inactive", null: false
    t.string "code", null: false
    t.string "suffix", null: false
    t.integer "determination_period_days"
    t.bigint "legislation_id"
    t.boolean "configured", default: false, null: false
    t.string "category"
    t.string "reporting_types", default: [], null: false, array: true
    t.string "decisions", default: [], null: false, array: true
    t.string "disclaimer"
    t.index ["code"], name: "ix_application_type_configs_on_code", unique: true, where: "((status)::text <> 'retired'::text)"
    t.index ["legislation_id"], name: "ix_application_type_configs_on_legislation_id"
    t.index ["suffix"], name: "ix_application_type_configs_on_suffix", unique: true
  end

  create_table "application_types", force: :cascade do |t|
    t.string "name", null: false
    t.integer "part"
    t.string "section"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assessment_details", array: true
    t.string "steps", default: ["validation", "consultation", "assessment", "review"], array: true
    t.string "consistency_checklist", array: true
    t.jsonb "document_tags", default: {}, null: false
    t.jsonb "features", default: {}
    t.string "status", default: "inactive", null: false
    t.string "code", null: false
    t.string "suffix", null: false
    t.integer "determination_period_days"
    t.bigint "legislation_id"
    t.boolean "configured", default: false, null: false
    t.string "category"
    t.string "reporting_types", default: [], null: false, array: true
    t.string "decisions", default: [], null: false, array: true
    t.bigint "config_id"
    t.bigint "local_authority_id"
    t.string "disclaimer"
    t.index ["config_id"], name: "ix_application_types_on_config_id"
    t.index ["legislation_id"], name: "ix_application_types_on_legislation_id"
    t.index ["local_authority_id", "code"], name: "ix_application_types_on_local_authority_id__code", unique: true, where: "((status)::text <> 'retired'::text)"
    t.index ["local_authority_id", "config_id"], name: "ix_application_types_on_local_authority_id__config_id", unique: true
    t.index ["local_authority_id", "suffix"], name: "ix_application_types_on_local_authority_id__suffix", unique: true
    t.index ["local_authority_id"], name: "ix_application_types_on_local_authority_id"
  end

  create_table "assessment_details", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.text "entry"
    t.string "assessment_status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category", null: false
    t.string "reviewer_verdict"
    t.string "review_status"
    t.index ["planning_application_id"], name: "ix_assessment_details_on_planning_application_id"
    t.index ["user_id"], name: "ix_assessment_details_on_user_id"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id"
    t.string "activity_type", null: false
    t.string "activity_information"
    t.string "audit_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "api_user_id"
    t.boolean "automated_activity", default: false, null: false
    t.index ["api_user_id"], name: "index_audits_on_api_user_id"
    t.index ["planning_application_id"], name: "index_audits_on_planning_application_id"
    t.index ["user_id"], name: "index_audits_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "text", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.datetime "deleted_at", precision: nil
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "ix_comments_on_user_id"
  end

  create_table "committee_decisions", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.boolean "recommend", default: false, null: false
    t.jsonb "reasons", array: true
    t.datetime "date_of_committee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.string "link"
    t.string "time"
    t.datetime "late_comments_deadline"
    t.text "notification_content"
    t.text "comments"
    t.index ["planning_application_id"], name: "ix_committee_decisions_on_planning_application_id", unique: true
  end

  create_table "condition_sets", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pre_commencement", default: false, null: false
    t.index ["planning_application_id"], name: "ix_condition_sets_on_planning_application_id"
  end

  create_table "conditions", force: :cascade do |t|
    t.string "title"
    t.text "text"
    t.text "reason"
    t.boolean "standard"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "condition_set_id"
    t.integer "position", default: 0, null: false
    t.datetime "cancelled_at"
    t.index ["condition_set_id"], name: "ix_conditions_on_condition_set_id"
  end

  create_table "consideration_sets", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_consideration_sets_on_planning_application_id"
  end

  create_table "considerations", force: :cascade do |t|
    t.bigint "consideration_set_id"
    t.string "policy_area", null: false
    t.jsonb "policy_references", default: [], null: false
    t.jsonb "policy_guidance", default: [], null: false
    t.text "assessment"
    t.text "conclusion"
    t.integer "position"
    t.bigint "submitted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "proposal"
    t.string "summary_tag"
    t.boolean "draft", default: false, null: false
    t.index ["consideration_set_id"], name: "ix_considerations_on_consideration_set_id"
    t.index ["submitted_by_id"], name: "ix_considerations_on_submitted_by_id"
  end

  create_table "consistency_checklists", force: :cascade do |t|
    t.integer "status", null: false
    t.integer "description_matches_documents", default: 0, null: false
    t.integer "documents_consistent", default: 0, null: false
    t.integer "proposal_details_match_documents", default: 0, null: false
    t.text "proposal_details_match_documents_comment"
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "site_map_correct", default: 0, null: false
    t.integer "proposal_measurements_match_documents", default: 0, null: false
    t.text "site_map_correct_comment"
    t.index ["planning_application_id"], name: "ix_consistency_checklists_on_planning_application_id"
  end

  create_table "constraints", force: :cascade do |t|
    t.string "type", null: false
    t.string "category", null: false
    t.bigint "local_authority_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "searchable_type_code"
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, ((((((COALESCE(category, ''::character varying))::text || ' '::text) || (COALESCE(type, ''::character varying))::text) || ' '::text) || (COALESCE(searchable_type_code, ''::character varying))::text) || ' '::text))", stored: true
    t.index ["local_authority_id", "type"], name: "ix_constraints_on_local_authority_id__type", unique: true
    t.index ["local_authority_id"], name: "ix_constraints_on_local_authority_id"
  end

  create_table "consultations", force: :cascade do |t|
    t.date "start_date"
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "not_started", null: false
    t.string "neighbour_letter_text"
    t.date "end_date"
    t.datetime "letter_copy_sent_at"
    t.jsonb "polygon_geojson"
    t.string "polygon_colour", default: "#d870fc", null: false
    t.geography "polygon_search", limit: {srid: 4326, type: "geometry_collection", geographic: true}
    t.string "consultee_message_subject"
    t.text "consultee_message_body"
    t.uuid "consultee_email_reply_to_id"
    t.index ["planning_application_id"], name: "ix_consultations_on_planning_application_id", unique: true
  end

  create_table "consultee_emails", force: :cascade do |t|
    t.bigint "consultee_id", null: false
    t.string "subject"
    t.text "body"
    t.datetime "sent_at"
    t.uuid "notify_id"
    t.string "status", default: "pending", null: false
    t.datetime "status_updated_at"
    t.string "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consultee_id"], name: "ix_consultee_emails_on_consultee_id"
  end

  create_table "consultee_responses", force: :cascade do |t|
    t.bigint "consultee_id", null: false
    t.string "name"
    t.string "email"
    t.text "response"
    t.datetime "received_at"
    t.text "redacted_response"
    t.bigint "redacted_by_id"
    t.datetime "redacted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "summary_tag"
    t.index ["consultee_id"], name: "ix_consultee_responses_on_consultee_id"
    t.index ["redacted_by_id"], name: "ix_consultee_responses_on_redacted_by_id"
  end

  create_table "consultees", force: :cascade do |t|
    t.string "name", null: false
    t.string "origin", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "consultation_id"
    t.string "role"
    t.string "organisation"
    t.string "email_address"
    t.string "status", default: "not_consulted"
    t.datetime "email_sent_at"
    t.datetime "email_delivered_at"
    t.datetime "last_email_sent_at"
    t.datetime "last_email_delivered_at"
    t.datetime "expires_at"
    t.datetime "last_response_at"
    t.datetime "magic_link_last_sent_at"
    t.index ["consultation_id"], name: "ix_consultees_on_consultation_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "local_authority_id"
    t.string "origin", null: false
    t.string "category", null: false
    t.string "name", null: false
    t.string "role"
    t.string "organisation"
    t.string "address_1"
    t.string "address_2"
    t.string "town"
    t.string "county"
    t.string "postcode"
    t.string "email_address"
    t.string "phone_number"
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, (((((COALESCE(name, ''::character varying))::text || ' '::text) || (COALESCE(role, ''::character varying))::text) || ' '::text) || (COALESCE(organisation, ''::character varying))::text))", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id", "category"], name: "ix_contacts_on_local_authority_id__category"
    t.index ["local_authority_id"], name: "ix_contacts_on_local_authority_id"
    t.index ["name"], name: "ix_contacts_on_name"
    t.index ["search"], name: "ix_contacts_on_search", using: :gin
  end

  create_table "decisions", force: :cascade do |t|
    t.string "code", null: false
    t.string "description", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "document_checklist_items", force: :cascade do |t|
    t.string "category", null: false
    t.jsonb "tags", default: [], null: false
    t.string "description", null: false
    t.bigint "document_checklist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_checklist_id"], name: "ix_document_checklist_items_on_document_checklist_id"
  end

  create_table "document_checklists", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_document_checklists_on_planning_application_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "archived_at", precision: nil
    t.string "archive_reason"
    t.string "numbers", default: "", null: false
    t.boolean "publishable", default: false
    t.boolean "referenced_in_decision_notice", default: false
    t.boolean "validated"
    t.text "invalidated_document_reason"
    t.text "applicant_description"
    t.bigint "user_id"
    t.bigint "api_user_id"
    t.datetime "received_at", precision: nil
    t.boolean "redacted", default: false, null: false
    t.bigint "evidence_group_id"
    t.bigint "site_visit_id"
    t.bigint "neighbour_response_id"
    t.bigint "site_notice_id"
    t.bigint "press_notice_id"
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "tags", default: [], array: true
    t.bigint "document_checklist_items_id"
    t.index ["api_user_id"], name: "ix_documents_on_api_user_id"
    t.index ["document_checklist_items_id"], name: "ix_documents_on_document_checklist_items_id"
    t.index ["evidence_group_id"], name: "ix_documents_on_evidence_group_id"
    t.index ["neighbour_response_id"], name: "ix_documents_on_neighbour_response_id"
    t.index ["owner_type", "owner_id"], name: "index_documents_on_owner"
    t.index ["planning_application_id"], name: "index_documents_on_planning_application_id"
    t.index ["press_notice_id"], name: "ix_documents_on_press_notice_id"
    t.index ["site_notice_id"], name: "ix_documents_on_site_notice_id"
    t.index ["site_visit_id"], name: "ix_documents_on_site_visit_id"
    t.index ["user_id"], name: "ix_documents_on_user_id"
  end

  create_table "environment_impact_assessments", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.string "address"
    t.integer "fee"
    t.boolean "required", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email_address"
    t.index ["planning_application_id"], name: "ix_environment_impact_assessments_on_planning_application_id"
  end

  create_table "evidence_groups", force: :cascade do |t|
    t.integer "tag"
    t.date "start_date"
    t.date "end_date"
    t.boolean "missing_evidence"
    t.string "missing_evidence_entry"
    t.string "applicant_comment"
    t.bigint "immunity_detail_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["immunity_detail_id"], name: "ix_evidence_groups_on_immunity_detail_id"
  end

  create_table "fee_calculations", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.decimal "total_fee", precision: 10, scale: 2
    t.decimal "payable_fee", precision: 10, scale: 2
    t.decimal "requested_fee", precision: 10, scale: 2
    t.string "exemptions", default: [], array: true
    t.string "reductions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_fee_calculations_on_planning_application_id"
  end

  create_table "heads_of_terms", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public", default: false, null: false
    t.index ["planning_application_id"], name: "ix_heads_of_terms_on_planning_application_id"
  end

  create_table "immunity_details", force: :cascade do |t|
    t.date "end_date"
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_immunity_details_on_planning_application_id"
  end

  create_table "informative_sets", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_informative_sets_on_planning_application_id"
  end

  create_table "informatives", force: :cascade do |t|
    t.string "title"
    t.text "text"
    t.bigint "informative_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["informative_set_id"], name: "ix_informatives_on_informative_set_id"
    t.index ["title", "informative_set_id"], name: "ix_informatives_on_title__informative_set_id", unique: true
  end

  create_table "land_owners", force: :cascade do |t|
    t.bigint "ownership_certificate_id", null: false
    t.string "name"
    t.string "address_1"
    t.string "address_2"
    t.string "town"
    t.string "county"
    t.string "country"
    t.string "postcode"
    t.boolean "notice_given", default: true, null: false
    t.datetime "notice_given_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notice_reason"
    t.index ["ownership_certificate_id"], name: "ix_land_owners_on_ownership_certificate_id"
  end

  create_table "legislation", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "local_authorities", force: :cascade do |t|
    t.string "subdomain", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signatory_name"
    t.string "signatory_job_title"
    t.text "enquiries_paragraph"
    t.string "email_address"
    t.string "feedback_email"
    t.string "reviewer_group_email"
    t.string "council_code", null: false
    t.string "notify_api_key"
    t.uuid "letter_template_id"
    t.string "press_notice_email"
    t.string "short_name", null: false
    t.string "council_name", null: false
    t.string "applicants_url", null: false
    t.uuid "email_reply_to_id"
    t.boolean "active", default: false, null: false
    t.string "telephone_number"
    t.string "document_checklist"
    t.string "planning_policy_and_guidance"
    t.string "notify_error_status"
    t.jsonb "application_type_overrides", default: []
    t.boolean "planning_history_enabled", default: false, null: false
    t.string "public_register_base_url"
    t.index ["subdomain"], name: "index_local_authorities_on_subdomain", unique: true
  end

  create_table "local_authority_informatives", force: :cascade do |t|
    t.bigint "local_authority_id"
    t.string "title"
    t.text "text"
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, ((((COALESCE(title, ''::character varying))::text || ' '::text) || COALESCE(text, ''::text)) || ' '::text))", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id"], name: "ix_local_authority_informatives_on_local_authority_id"
  end

  create_table "local_authority_policy_areas", force: :cascade do |t|
    t.bigint "local_authority_id", null: false
    t.string "description", null: false
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, (description)::text)", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id", "description"], name: "ix_local_authority_policy_areas_on_local_authority_id__descript", unique: true
    t.index ["local_authority_id", "search"], name: "ix_local_authority_policy_areas_on_local_authority_id__search", using: :gin
    t.index ["local_authority_id"], name: "ix_local_authority_policy_areas_on_local_authority_id"
  end

  create_table "local_authority_policy_areas_references", id: false, force: :cascade do |t|
    t.bigint "policy_area_id"
    t.bigint "policy_reference_id"
    t.index ["policy_area_id", "policy_reference_id"], name: "ix_local_authority_policy_areas_references_on_policy_area_id__p", unique: true
    t.index ["policy_area_id"], name: "ix_local_authority_policy_areas_references_on_policy_area_id"
    t.index ["policy_reference_id"], name: "ix_local_authority_policy_areas_references_on_policy_reference_"
  end

  create_table "local_authority_policy_guidances", force: :cascade do |t|
    t.bigint "local_authority_id", null: false
    t.string "description", null: false
    t.string "url"
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, (description)::text)", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id", "description"], name: "ix_local_authority_policy_guidances_on_local_authority_id__desc", unique: true
    t.index ["local_authority_id", "search"], name: "ix_local_authority_policy_guidances_on_local_authority_id__sear", using: :gin
    t.index ["local_authority_id"], name: "ix_local_authority_policy_guidances_on_local_authority_id"
  end

  create_table "local_authority_policy_references", force: :cascade do |t|
    t.bigint "local_authority_id", null: false
    t.string "code", null: false
    t.string "description", null: false
    t.string "url"
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, (((code)::text || ' '::text) || (description)::text))", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id", "code"], name: "ix_local_authority_policy_references_on_local_authority_id__cod", unique: true
    t.index ["local_authority_id", "description"], name: "ix_local_authority_policy_references_on_local_authority_id__des", unique: true
    t.index ["local_authority_id", "search"], name: "ix_local_authority_policy_references_on_local_authority_id__sea", using: :gin
    t.index ["local_authority_id"], name: "ix_local_authority_policy_references_on_local_authority_id"
  end

  create_table "local_authority_requirements", force: :cascade do |t|
    t.bigint "local_authority_id", null: false
    t.string "description", null: false
    t.string "url"
    t.text "guidelines"
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, (description)::text)", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category", limit: 30, null: false
    t.index ["local_authority_id", "description"], name: "ix_local_authority_requirements_on_local_authority_id__descript", unique: true
    t.index ["local_authority_id", "search"], name: "ix_local_authority_requirements_on_local_authority_id__search", using: :gin
    t.index ["local_authority_id"], name: "ix_local_authority_requirements_on_local_authority_id"
  end

  create_table "local_policies", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_local_policies_on_planning_application_id"
  end

  create_table "local_policy_areas", force: :cascade do |t|
    t.string "area"
    t.string "policies"
    t.string "guidance"
    t.text "assessment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "local_policy_id"
    t.text "conclusion"
    t.index ["local_policy_id"], name: "ix_local_policy_areas_on_local_policy_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.bigint "created_by_id", null: false
    t.bigint "planning_application_id"
    t.string "status", default: "not_started", null: false
    t.text "comment"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "ix_meetings_on_created_by_id"
    t.index ["planning_application_id"], name: "ix_meetings_on_planning_application_id"
  end

  create_table "neighbour_letter_batches", force: :cascade do |t|
    t.bigint "consultation_id"
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consultation_id"], name: "ix_neighbour_letter_batches_on_consultation_id"
  end

  create_table "neighbour_letters", force: :cascade do |t|
    t.bigint "neighbour_id", null: false
    t.string "text"
    t.string "sent_at"
    t.jsonb "notify_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notify_id"
    t.string "status"
    t.string "status_updated_at"
    t.string "failure_reason"
    t.string "resend_reason"
    t.bigint "batch_id"
    t.index ["batch_id"], name: "ix_neighbour_letters_on_batch_id"
    t.index ["neighbour_id"], name: "ix_neighbour_letters_on_neighbour_id"
  end

  create_table "neighbour_responses", force: :cascade do |t|
    t.bigint "neighbour_id"
    t.string "name"
    t.string "response"
    t.string "email"
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "summary_tag"
    t.text "redacted_response"
    t.bigint "consultation_id"
    t.bigint "redacted_by_id"
    t.string "tags", default: [], array: true
    t.index ["consultation_id"], name: "ix_neighbour_responses_on_consultation_id"
    t.index ["neighbour_id"], name: "ix_neighbour_responses_on_neighbour_id"
    t.index ["redacted_by_id"], name: "ix_neighbour_responses_on_redacted_by_id"
  end

  create_table "neighbours", force: :cascade do |t|
    t.string "address"
    t.bigint "consultation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "selected", default: true
    t.datetime "last_letter_sent_at"
    t.string "source"
    t.geography "lonlat", limit: {srid: 4326, type: "st_point", geographic: true}
    t.index "lower((address)::text), consultation_id", name: "index_neighbours_on_lower_address_and_consultation_id", unique: true
    t.index ["consultation_id"], name: "ix_neighbours_on_consultation_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "user_id", null: false
    t.text "entry", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_notes_on_planning_application_id"
    t.index ["user_id"], name: "ix_notes_on_user_id"
  end

  create_table "old_policies", force: :cascade do |t|
    t.string "section", null: false
    t.string "description", null: false
    t.integer "status", null: false
    t.bigint "policy_class_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["policy_class_id"], name: "ix_old_policies_on_policy_class_id"
  end

  create_table "old_policy_classes", force: :cascade do |t|
    t.string "schedule", null: false
    t.integer "part", null: false
    t.string "section", null: false
    t.string "url"
    t.string "name", null: false
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_old_policy_classes_on_planning_application_id"
  end

  create_table "ownership_certificates", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.string "certificate_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_ownership_certificates_on_planning_application_id"
  end

  create_table "permitted_development_rights", force: :cascade do |t|
    t.string "status", null: false
    t.boolean "removed"
    t.text "removed_reason"
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "review_status", default: "review_not_started", null: false
    t.text "reviewer_comment"
    t.boolean "reviewer_edited", default: false, null: false
    t.boolean "accepted", default: false, null: false
    t.datetime "reviewed_at", precision: nil
    t.bigint "assessor_id"
    t.bigint "reviewer_id"
    t.index ["assessor_id"], name: "ix_permitted_development_rights_on_assessor_id"
    t.index ["planning_application_id"], name: "ix_permitted_development_rights_on_planning_application_id"
    t.index ["reviewer_id"], name: "ix_permitted_development_rights_on_reviewer_id"
  end

  create_table "planning_application_constraints", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.bigint "planning_application_constraints_query_id"
    t.bigint "constraint_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "removed_at"
    t.jsonb "data"
    t.jsonb "metadata"
    t.boolean "identified", default: false, null: false
    t.string "identified_by", null: false
    t.bigint "consultee_id"
    t.boolean "consultation_required", default: true, null: false
    t.string "status", default: "pending", null: false
    t.index ["constraint_id"], name: "ix_planning_application_constraints_on_constraint_id"
    t.index ["consultee_id"], name: "ix_planning_application_constraints_on_consultee_id"
    t.index ["planning_application_constraints_query_id"], name: "ix_planning_application_constraints_on_planning_application_con"
    t.index ["planning_application_id"], name: "ix_planning_application_constraints_on_planning_application_id"
  end

  create_table "planning_application_constraints_queries", force: :cascade do |t|
    t.jsonb "geojson"
    t.text "wkt"
    t.string "planx_query", null: false
    t.string "planning_data_query", null: false
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_planning_application_constraints_queries_on_planning_applica"
  end

  create_table "planning_application_policy_classes", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "policy_class_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_planning_application_policy_classes_on_planning_application_"
    t.index ["policy_class_id", "planning_application_id"], name: "ix_pa_policy_classes_on_policy_class_and_pa", unique: true
    t.index ["policy_class_id"], name: "ix_planning_application_policy_classes_on_policy_class_id"
  end

  create_table "planning_application_policy_sections", force: :cascade do |t|
    t.string "status"
    t.bigint "planning_application_id", null: false
    t.bigint "policy_section_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description", null: false
    t.index ["planning_application_id"], name: "ix_planning_application_policy_sections_on_planning_application"
    t.index ["policy_section_id"], name: "ix_planning_application_policy_sections_on_policy_section_id"
  end

  create_table "planning_application_requirements", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.string "description", null: false
    t.string "url"
    t.text "guidelines"
    t.text "additional_comments"
    t.string "source", default: "BOPS"
    t.string "category", limit: 30
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_planning_application_requirements_on_planning_application_id"
  end

  create_table "planning_applications", force: :cascade do |t|
    t.date "target_date", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at", precision: nil
    t.datetime "determined_at", precision: nil
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.datetime "awaiting_determination_at", precision: nil
    t.datetime "in_assessment_at", precision: nil
    t.datetime "to_be_reviewed_at", precision: nil
    t.jsonb "proposal_details"
    t.string "agent_first_name"
    t.string "agent_last_name"
    t.string "agent_phone"
    t.string "agent_email"
    t.string "applicant_first_name"
    t.string "applicant_last_name"
    t.string "applicant_email"
    t.string "applicant_phone"
    t.bigint "local_authority_id"
    t.datetime "invalidated_at", precision: nil
    t.datetime "withdrawn_at", precision: nil
    t.datetime "returned_at", precision: nil
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
    t.jsonb "boundary_geojson"
    t.string "change_access_id"
    t.date "expiry_date"
    t.decimal "payment_amount", precision: 10, scale: 2
    t.string "result_flag"
    t.text "result_heading"
    t.text "result_description"
    t.string "result_override"
    t.bigint "api_user_id"
    t.bigint "boundary_created_by_id"
    t.datetime "assessment_in_progress_at", precision: nil
    t.string "ward"
    t.string "ward_type"
    t.string "latitude"
    t.string "longitude"
    t.datetime "closed_at", precision: nil
    t.datetime "determination_date", precision: nil
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
    t.datetime "validated_at", precision: nil
    t.datetime "received_at", precision: nil
    t.string "review_documents_for_recommendation_status", default: "not_started", null: false
    t.boolean "from_production", default: false
    t.text "changed_constraints", array: true
    t.bigint "application_type_id"
    t.boolean "make_public", default: false
    t.boolean "legislation_checked", default: false, null: false
    t.boolean "cil_liable"
    t.geography "lonlat", limit: {srid: 4326, type: "st_point", geographic: true}
    t.datetime "not_started_at"
    t.boolean "valid_ownership_certificate"
    t.boolean "valid_description"
    t.string "reporting_type"
    t.geography "neighbour_boundary_geojson", limit: {srid: 4326, type: "geometry_collection", geographic: true}
    t.string "documents_status", default: "not_started", null: false
    t.datetime "in_committee_at"
    t.boolean "regulation_3", default: false, null: false
    t.boolean "regulation_4", default: false, null: false
    t.boolean "ownership_certificate_checked", default: false, null: false
    t.datetime "published_at"
    t.boolean "site_history_checked", default: false, null: false
    t.virtual "address_search", type: :tsvector, as: "to_tsvector('simple'::regconfig, (((((((((COALESCE(address_1, ''::character varying))::text || ' '::text) || (COALESCE(address_2, ''::character varying))::text) || ' '::text) || (COALESCE(town, ''::character varying))::text) || ' '::text) || (COALESCE(county, ''::character varying))::text) || ' '::text) || (COALESCE(postcode, ''::character varying))::text))", stored: true
    t.datetime "deleted_at"
    t.string "previous_references", default: [], array: true
    t.string "reporting_type_code"
    t.bigint "recommended_application_type_id"
    t.index "lower((reference)::text)", name: "ix_planning_applications_on_lower_reference"
    t.index "lower(replace((postcode)::text, ' '::text, ''::text))", name: "ix_planning_applications_on_LOWER_replace_postcode"
    t.index "to_tsvector('english'::regconfig, description)", name: "index_planning_applications_on_description", using: :gin
    t.index ["address_search"], name: "ix_planning_applications_on_address_search", using: :gin
    t.index ["api_user_id"], name: "ix_planning_applications_on_api_user_id"
    t.index ["application_number", "local_authority_id"], name: "ix_planning_applications_on_application_number__local_authority", unique: true
    t.index ["application_type_id"], name: "ix_planning_applications_on_application_type_id"
    t.index ["boundary_created_by_id"], name: "ix_planning_applications_on_boundary_created_by_id"
    t.index ["deleted_at"], name: "ix_planning_applications_on_deleted_at"
    t.index ["local_authority_id"], name: "index_planning_applications_on_local_authority_id"
    t.index ["lonlat"], name: "ix_planning_applications_on_lonlat", using: :gist
    t.index ["recommended_application_type_id"], name: "ix_planning_applications_on_recommended_application_type_id"
    t.index ["reference", "local_authority_id"], name: "ix_planning_applications_on_reference__local_authority_id", unique: true
    t.index ["status", "application_type_id"], name: "ix_planning_applications_on_status__application_type_id"
    t.index ["status"], name: "ix_planning_applications_on_status"
    t.index ["user_id"], name: "index_planning_applications_on_user_id"
  end

  create_table "planx_planning_data", force: :cascade do |t|
    t.jsonb "entry"
    t.bigint "planning_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "session_id"
    t.jsonb "params_v1"
    t.jsonb "params_v2"
    t.index ["planning_application_id"], name: "ix_planx_planning_data_on_planning_application_id"
  end

  create_table "policy_classes", force: :cascade do |t|
    t.string "section", null: false
    t.string "name", null: false
    t.string "url"
    t.bigint "policy_part_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["policy_part_id"], name: "ix_policy_classes_on_policy_part_id"
    t.index ["section", "policy_part_id"], name: "ix_policy_classes_on_section__policy_part_id", unique: true
  end

  create_table "policy_parts", force: :cascade do |t|
    t.integer "number", null: false
    t.string "name", null: false
    t.bigint "policy_schedule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["number", "policy_schedule_id"], name: "ix_policy_parts_on_number__policy_schedule_id", unique: true
    t.index ["policy_schedule_id"], name: "ix_policy_parts_on_policy_schedule_id"
  end

  create_table "policy_schedules", force: :cascade do |t|
    t.integer "number", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "ix_policy_schedules_on_number", unique: true
  end

  create_table "policy_sections", force: :cascade do |t|
    t.string "section", null: false
    t.text "description", null: false
    t.bigint "policy_class_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", default: "Other", null: false
    t.index ["policy_class_id"], name: "ix_policy_sections_on_policy_class_id"
    t.index ["section", "policy_class_id"], name: "ix_policy_sections_on_section__policy_class_id", unique: true
  end

  create_table "press_notices", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.boolean "required", null: false
    t.jsonb "reasons"
    t.datetime "requested_at"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comment"
    t.text "other_reason"
    t.date "expiry_date"
    t.index ["planning_application_id"], name: "ix_press_notices_on_planning_application_id"
  end

  create_table "proposal_measurements", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.float "eaves_height"
    t.float "depth"
    t.float "max_height"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planning_application_id"], name: "ix_proposal_measurements_on_planning_application_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.bigint "planning_application_id", null: false
    t.bigint "assessor_id"
    t.bigint "reviewer_id"
    t.text "assessor_comment"
    t.text "reviewer_comment"
    t.datetime "reviewed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "challenged"
    t.boolean "submitted"
    t.integer "status", default: 0, null: false
    t.boolean "committee_overturned", default: false, null: false
    t.index ["assessor_id"], name: "index_recommendations_on_assessor_id"
    t.index ["planning_application_id"], name: "index_recommendations_on_planning_application_id"
    t.index ["reviewer_id"], name: "index_recommendations_on_reviewer_id"
  end

  create_table "reporting_types", force: :cascade do |t|
    t.string "code", null: false
    t.string "description", null: false
    t.string "guidance"
    t.string "guidance_link"
    t.string "legislation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "code_prefix", type: :text, as: "regexp_replace((code)::text, '[0-9]+$'::text, ''::text)", stored: true
    t.virtual "code_suffix", type: :integer, as: "(regexp_replace((code)::text, '^[A-Z]+'::text, ''::text))::integer", stored: true
    t.string "categories", default: [], null: false, array: true
    t.index ["code"], name: "ix_reporting_types_on_code", unique: true
    t.index ["code_prefix", "code_suffix"], name: "ix_reporting_types_on_code_prefix__code_suffix"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "action"
    t.bigint "assessor_id"
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewer_id"
    t.text "comment"
    t.string "status", default: "not_started", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "review_status", default: "review_not_started", null: false
    t.boolean "reviewer_edited", default: false, null: false
    t.jsonb "specific_attributes"
    t.index ["assessor_id"], name: "ix_reviews_on_assessor_id"
    t.index ["owner_type", "owner_id"], name: "index_reviews_on_reviewable"
    t.index ["reviewer_id"], name: "ix_reviews_on_reviewer_id"
  end

  create_table "site_histories", force: :cascade do |t|
    t.date "date"
    t.string "application_number"
    t.string "description"
    t.string "decision"
    t.bigint "planning_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comment"
    t.index ["planning_application_id"], name: "ix_site_histories_on_planning_application_id"
  end

  create_table "site_notices", force: :cascade do |t|
    t.bigint "planning_application_id"
    t.boolean "required"
    t.text "content"
    t.datetime "displayed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "expiry_date"
    t.string "internal_team_email"
    t.index ["planning_application_id"], name: "ix_site_notices_on_planning_application_id"
  end

  create_table "site_visits", force: :cascade do |t|
    t.bigint "consultation_id"
    t.bigint "created_by_id", null: false
    t.string "status", default: "not_started", null: false
    t.text "comment", null: false
    t.boolean "decision", null: false
    t.datetime "visited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "neighbour_id"
    t.bigint "planning_application_id", null: false
    t.string "address"
    t.index ["consultation_id"], name: "ix_site_visits_on_consultation_id"
    t.index ["created_by_id"], name: "ix_site_visits_on_created_by_id"
    t.index ["neighbour_id"], name: "ix_site_visits_on_neighbour_id"
    t.index ["planning_application_id"], name: "ix_site_visits_on_planning_application_id"
  end

  create_table "terms", force: :cascade do |t|
    t.string "title", null: false
    t.text "text", null: false
    t.bigint "heads_of_term_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.datetime "cancelled_at"
    t.index ["heads_of_term_id"], name: "ix_terms_on_heads_of_term_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0
    t.string "name"
    t.bigint "local_authority_id"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: true, null: false
    t.string "mobile_number"
    t.integer "otp_delivery_method", default: 0
    t.string "otp_secret"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "persistence_token"
    t.datetime "deactivated_at"
    t.index ["confirmation_token"], name: "ix_users_on_confirmation_token", unique: true
    t.index ["deactivated_at"], name: "ix_users_on_deactivated_at"
    t.index ["email", "local_authority_id"], name: "index_users_on_email_and_local_authority_id", unique: true
    t.index ["local_authority_id"], name: "index_users_on_local_authority_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "validation_requests", force: :cascade do |t|
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "planning_application_id"
    t.datetime "closed_at", precision: nil
    t.boolean "update_counter", default: false, null: false
    t.string "state"
    t.bigint "user_id"
    t.boolean "post_validation", default: false, null: false
    t.boolean "approved"
    t.text "reason"
    t.string "rejection_reason"
    t.text "response"
    t.datetime "notified_at"
    t.datetime "cancelled_at"
    t.text "cancel_reason"
    t.boolean "auto_closed", default: false, null: false
    t.datetime "auto_closed_at"
    t.bigint "old_document_id"
    t.integer "sequence"
    t.jsonb "specific_attributes"
    t.string "owner_type"
    t.bigint "owner_id"
    t.date "proposed_expiry_date"
    t.index ["old_document_id"], name: "ix_validation_requests_on_old_document_id"
    t.index ["owner_type", "owner_id"], name: "index_validation_requests_on_owner"
    t.index ["planning_application_id"], name: "ix_validation_requests_on_planning_application_id"
    t.index ["user_id"], name: "ix_validation_requests_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "additional_services", "planning_applications"
  add_foreign_key "api_users", "local_authorities"
  add_foreign_key "appeals", "planning_applications"
  add_foreign_key "application_type_configs", "legislation"
  add_foreign_key "application_types", "application_type_configs", column: "config_id"
  add_foreign_key "application_types", "legislation"
  add_foreign_key "application_types", "local_authorities"
  add_foreign_key "assessment_details", "planning_applications"
  add_foreign_key "assessment_details", "users"
  add_foreign_key "audits", "api_users"
  add_foreign_key "audits", "planning_applications"
  add_foreign_key "audits", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "condition_sets", "planning_applications"
  add_foreign_key "conditions", "condition_sets"
  add_foreign_key "consideration_sets", "planning_applications"
  add_foreign_key "considerations", "consideration_sets"
  add_foreign_key "considerations", "users", column: "submitted_by_id"
  add_foreign_key "consistency_checklists", "planning_applications"
  add_foreign_key "constraints", "local_authorities"
  add_foreign_key "consultations", "planning_applications"
  add_foreign_key "consultee_emails", "consultees"
  add_foreign_key "consultee_responses", "consultees"
  add_foreign_key "consultee_responses", "users", column: "redacted_by_id"
  add_foreign_key "consultees", "consultations"
  add_foreign_key "contacts", "local_authorities"
  add_foreign_key "document_checklists", "planning_applications"
  add_foreign_key "documents", "api_users"
  add_foreign_key "documents", "document_checklist_items", column: "document_checklist_items_id"
  add_foreign_key "documents", "evidence_groups"
  add_foreign_key "documents", "neighbour_responses"
  add_foreign_key "documents", "planning_applications"
  add_foreign_key "documents", "press_notices"
  add_foreign_key "documents", "site_notices"
  add_foreign_key "documents", "site_visits"
  add_foreign_key "documents", "users"
  add_foreign_key "evidence_groups", "immunity_details"
  add_foreign_key "fee_calculations", "planning_applications"
  add_foreign_key "immunity_details", "planning_applications"
  add_foreign_key "local_authority_policy_areas", "local_authorities"
  add_foreign_key "local_authority_policy_areas_references", "local_authority_policy_areas", column: "policy_area_id"
  add_foreign_key "local_authority_policy_areas_references", "local_authority_policy_references", column: "policy_reference_id"
  add_foreign_key "local_authority_policy_guidances", "local_authorities"
  add_foreign_key "local_authority_policy_references", "local_authorities"
  add_foreign_key "local_authority_requirements", "local_authorities"
  add_foreign_key "local_policies", "planning_applications"
  add_foreign_key "local_policy_areas", "local_policies"
  add_foreign_key "meetings", "planning_applications"
  add_foreign_key "meetings", "users", column: "created_by_id"
  add_foreign_key "neighbour_letter_batches", "consultations"
  add_foreign_key "neighbour_letters", "neighbour_letter_batches", column: "batch_id"
  add_foreign_key "neighbour_letters", "neighbours"
  add_foreign_key "neighbour_responses", "consultations"
  add_foreign_key "neighbour_responses", "neighbours"
  add_foreign_key "neighbour_responses", "users", column: "redacted_by_id"
  add_foreign_key "neighbours", "consultations"
  add_foreign_key "notes", "planning_applications"
  add_foreign_key "notes", "users"
  add_foreign_key "old_policies", "old_policy_classes", column: "policy_class_id"
  add_foreign_key "old_policy_classes", "planning_applications"
  add_foreign_key "permitted_development_rights", "planning_applications"
  add_foreign_key "permitted_development_rights", "users", column: "assessor_id"
  add_foreign_key "permitted_development_rights", "users", column: "reviewer_id"
  add_foreign_key "planning_application_constraints", "constraints"
  add_foreign_key "planning_application_constraints", "consultees"
  add_foreign_key "planning_application_constraints", "planning_application_constraints_queries"
  add_foreign_key "planning_application_constraints", "planning_applications"
  add_foreign_key "planning_application_constraints_queries", "planning_applications"
  add_foreign_key "planning_application_policy_classes", "planning_applications"
  add_foreign_key "planning_application_policy_classes", "policy_classes"
  add_foreign_key "planning_application_policy_sections", "planning_applications"
  add_foreign_key "planning_application_policy_sections", "policy_sections"
  add_foreign_key "planning_application_requirements", "planning_applications"
  add_foreign_key "planning_applications", "api_users"
  add_foreign_key "planning_applications", "application_types"
  add_foreign_key "planning_applications", "application_types", column: "recommended_application_type_id"
  add_foreign_key "planning_applications", "local_authorities"
  add_foreign_key "planning_applications", "users"
  add_foreign_key "planning_applications", "users", column: "boundary_created_by_id"
  add_foreign_key "planx_planning_data", "planning_applications"
  add_foreign_key "policy_classes", "policy_parts"
  add_foreign_key "policy_parts", "policy_schedules"
  add_foreign_key "policy_sections", "policy_classes"
  add_foreign_key "press_notices", "planning_applications"
  add_foreign_key "proposal_measurements", "planning_applications"
  add_foreign_key "recommendations", "planning_applications"
  add_foreign_key "recommendations", "users", column: "assessor_id"
  add_foreign_key "recommendations", "users", column: "reviewer_id"
  add_foreign_key "reviews", "users", column: "assessor_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "site_histories", "planning_applications"
  add_foreign_key "site_notices", "planning_applications"
  add_foreign_key "site_visits", "consultations"
  add_foreign_key "site_visits", "neighbours"
  add_foreign_key "site_visits", "planning_applications"
  add_foreign_key "site_visits", "users", column: "created_by_id"
  add_foreign_key "users", "local_authorities"
  add_foreign_key "validation_requests", "documents", column: "old_document_id"
  add_foreign_key "validation_requests", "planning_applications"
end
