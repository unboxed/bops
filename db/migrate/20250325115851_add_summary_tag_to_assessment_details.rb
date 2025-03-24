# frozen_string_literal: true

class AddSummaryTagToAssessmentDetails < ActiveRecord::Migration[7.2]
  def change
    add_column :assessment_details, :summary_tag, :string
  end
end
