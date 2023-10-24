# frozen_string_literal: true

class AddConsulteeTables < ActiveRecord::Migration[7.0]
  class Consultation < ActiveRecord::Base; end
  class Consultee < ActiveRecord::Base; end
  class ConsulteeResponse < ActiveRecord::Base; end

  def up
    add_column :consultations, :consultee_email_subject, :string
    add_column :consultations, :consultee_email_body, :text

    change_column :consultees, :origin, :string, null: false

    Consultee.where(origin: "0").update_all(origin: "internal")
    Consultee.where(origin: "1").update_all(origin: "external")

    add_column :consultees, :role, :string
    add_column :consultees, :organisation, :string
    add_column :consultees, :email_address, :string
    add_column :consultees, :status, :string, default: "not_consulted"
    add_column :consultees, :selected, :boolean, default: true
    add_column :consultees, :email_sent_at, :datetime

    # Needed to ensure that `add_foreign_key` works but data
    # should be checked before deployment to staging/production.
    consultation_ids = Consultation.ids
    Consultee.where.not(consultation_id: consultation_ids).delete_all

    add_foreign_key :consultees, :consultations

    create_table :consultee_emails do |t|
      t.references :consultee, null: false, index: true, foreign_key: true
      t.string :subject
      t.text :body
      t.datetime :sent_at
      t.uuid :notify_id
      t.string :status, null: false, default: "pending"
      t.datetime :status_updated_at
      t.string :failure_reason
      t.timestamps
    end

    create_table :consultee_responses do |t|
      t.references :consultee, null: false, index: true, foreign_key: true
      t.string :name
      t.string :email
      t.text :response
      t.datetime :received_at
      t.text :redacted_response
      t.references :redacted_by, index: true, foreign_key: { to_table: :users }
      t.datetime :redacted_at
      t.timestamps
    end

    Consultee.find_each do |consultee|
      ConsulteeResponse.create!(
        consultee_id: consultee.id,
        name: consultee.name,
        response: consultee.response,
        received_at: consultee.created_at
      )
    end
  end

  def down
    drop_table :consultee_responses
    drop_table :consultee_emails

    remove_foreign_key :consultees, :consultations

    remove_column :consultees, :email_sent_at
    remove_column :consultees, :selected
    remove_column :consultees, :status
    remove_column :consultees, :email_address
    remove_column :consultees, :organisation
    remove_column :consultees, :role

    Consultee.where(origin: "internal").update_all(origin: "0")
    Consultee.where(origin: "external").update_all(origin: "1")

    change_column :consultees, :origin, :integer, null: false, using: "origin::integer"

    remove_column :consultations, :consultee_email_body
    remove_column :consultations, :consultee_email_subject
  end
end
