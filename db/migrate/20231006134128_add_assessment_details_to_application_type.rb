# frozen_string_literal: true

class AddAssessmentDetailsToApplicationType < ActiveRecord::Migration[7.0]
  def change
    add_column :application_types, :assessment_details, :string, array: true

    ApplicationType.all.find_each do |type|
      details = case type.name.to_sym
      when :lawfulness_certificate
        %w[
          summary_of_work
          site_description
          consultation_summary
          additional_evidence
        ]
      when :prior_approval
        %w[
          summary_of_work
          site_description
          additional_evidence
          publicity_summary
          amenity
        ]
      else
        %w[
          summary_of_work
          site_description
          additional_evidence
          consultation_summary
          publicity_summary
        ]
      end
      type.update(assessment_details: details)
    end
  end
end
