# frozen_string_literal: true

class CreateApplicationTypeDecisionNotices < ActiveRecord::Migration[7.2]
  def change
    create_table :application_type_decision_notices do |t|
      t.references :application_type, null: false, index: {unique: true}, foreign_key: true
      t.text :template, null: false
      t.string :status, null: false, default: "not_started"
      t.timestamps
    end
  end
end
