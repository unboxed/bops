# frozen_string_literal: true

class AddAuditableToAudits < ActiveRecord::Migration[8.1]
  def change
    add_column :audits, :auditable_type, :string
    add_column :audits, :auditable_id, :bigint
    add_index :audits, [:auditable_type, :auditable_id]
  end
end
