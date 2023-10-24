# frozen_string_literal: true

class AddReviewDocumentsForRecommendationStatusToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :review_documents_for_recommendation_status, :string, default: "not_started",
      null: false
  end
end
