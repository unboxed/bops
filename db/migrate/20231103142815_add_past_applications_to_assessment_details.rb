# frozen_string_literal: true

class AddPastApplicationsToAssessmentDetails < ActiveRecord::Migration[7.0]
  def up
    ApplicationType.all.find_each do |type|
      type.assessment_details << "past_applications"
      type.save
    end
  end

  def down
    ApplicationType.all.find_each do |type|
      type.assessment_details.delete("past_applications")
      type.save
    end
  end
end
