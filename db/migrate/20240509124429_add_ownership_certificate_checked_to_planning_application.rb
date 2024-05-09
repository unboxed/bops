# frozen_string_literal: true

class AddOwnershipCertificateCheckedToPlanningApplication < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :ownership_certificate_checked, :boolean, default: false, null: false
  end
end
