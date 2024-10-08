# frozen_string_literal: true

class DropPastApplicationsCategoryFromAssessmentDetails < ActiveRecord::Migration[7.1]
  def up
    AssessmentDetail.where(category: :past_applications).delete_all
  end

  def down
  end
end
