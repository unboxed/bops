# frozen_string_literal: true

class AddValidOwnershipCertificateToPlanningApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :valid_ownership_certificate, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
