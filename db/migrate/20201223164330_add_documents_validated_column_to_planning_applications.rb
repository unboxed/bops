# frozen_string_literal: true

class AddDocumentsValidatedColumnToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :documents_validated_at, :date
  end
end
