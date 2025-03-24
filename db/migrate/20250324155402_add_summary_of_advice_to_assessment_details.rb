# frozen_string_literal: true

class AddSummaryOfAdviceToAssessmentDetails < ActiveRecord::Migration[7.2]
  def up
    ApplicationType::Config.find_by(code: "preApp").try(:tap) do |pre_app|
      pre_app.assessment_details << "summary_of_advice"
      pre_app.save
    end
  end

  def down
    ApplicationType::Config.find_by(code: "preApp").try(:tap) do |pre_app|
      pre_app.assessment_details.delete("summary_of_advice")
      pre_app.save
    end
  end
end
