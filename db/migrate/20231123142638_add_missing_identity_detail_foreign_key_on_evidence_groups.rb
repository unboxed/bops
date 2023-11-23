# frozen_string_literal: true

class AddMissingIdentityDetailForeignKeyOnEvidenceGroups < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :evidence_groups, :immunity_details
  end
end
