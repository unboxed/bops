# frozen_string_literal: true

class AddAdditionalInformationToAssessmentDetails < ActiveRecord::Migration[6.1]
  def change
    add_column(:assessment_details, :additional_information, :text)
  end
end
