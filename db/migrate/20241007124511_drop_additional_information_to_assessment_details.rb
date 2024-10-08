# frozen_string_literal: true

class DropAdditionalInformationToAssessmentDetails < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :assessment_details, :additional_information, :text }
  end
end
