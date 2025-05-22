# frozen_string_literal: true

class AddApplicationPayloadToSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :submissions, :application_payload, :jsonb, null: false, default: {}
  end
end
