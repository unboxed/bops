# frozen_string_literal: true

# rubocop:disable Rails/ThreeStateBooleanColumn
class AddConsultationRequiredToPlanningApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :consultation_required, :boolean
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
