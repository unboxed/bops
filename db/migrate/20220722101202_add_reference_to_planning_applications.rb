# frozen_string_literal: true

class AddReferenceToPlanningApplications < ActiveRecord::Migration[6.1]
  class PlanningApplication < ApplicationRecord
    def set_reference
      self.reference = [
        created_at.strftime("%y"),
        application_number,
        application_type_code
      ].join("-")
    end

    private

    enum application_type: { lawfulness_certificate: 0, full: 1 }

    def application_number
      self[:application_number].to_s.rjust(5, "0")
    end

    def application_type_code
      I18n.t("application_type_codes.#{application_type}.#{work_status}")
    end
  end

  def up
    add_column :planning_applications, :reference, :string
    add_index :planning_applications, "lower(reference)"

    add_index(
      :planning_applications,
      %i[reference local_authority_id],
      unique: true
    )

    PlanningApplication.all.find_each do |planning_application|
      planning_application.set_reference
      planning_application.save!
    end

    change_column_null :planning_applications, :application_number, false
  end

  def down
    remove_column :planning_applications, :reference
  end
end
