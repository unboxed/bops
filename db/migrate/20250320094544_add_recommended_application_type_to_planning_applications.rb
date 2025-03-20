# frozen_string_literal: true

class AddRecommendedApplicationTypeToPlanningApplications < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :planning_applications, :recommended_application_type, index: {algorithm: :concurrently}
  end
end
