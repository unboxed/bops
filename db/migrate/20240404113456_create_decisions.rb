# frozen_string_literal: true

class CreateDecisions < ActiveRecord::Migration[7.1]
  class Decision < ActiveRecord::Base; end

  DECISIONS = [
    ["granted", "Granted", "certificate-of-lawfulness"],
    ["refused", "Refused", "certificate-of-lawfulness"],
    ["granted", "Prior approval required and approved", "prior-approval"],
    ["not_required", "Prior approval not required", "prior-approval"],
    ["refused", "Prior approval required and refused", "prior-approval"],
    ["granted", "Granted", "full"],
    ["refused", "Refused", "full"],
    ["granted", "Granted", "householder"],
    ["refused", "Refused", "householder"]
  ]

  def change
    create_table :decisions do |t|
      t.string :code, null: false
      t.string :description, null: false
      t.string :category, null: false

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        DECISIONS.each do |code, description, category|
          Decision.create!(code:, description:, category:)
        end
      end

      dir.down do
        Decision.delete_all
      end
    end
  end
end
