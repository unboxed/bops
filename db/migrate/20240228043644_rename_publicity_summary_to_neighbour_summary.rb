# frozen_string_literal: true

class RenamePublicitySummaryToNeighbourSummary < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end
  class AssessmentDetail < ActiveRecord::Base; end

  def up
    ApplicationType.find_each do |type|
      case type.name
      when "lawfulness_certificate"
        type.assessment_details = %w[
          summary_of_work
          site_description
          consultation_summary
          additional_evidence
          past_applications
        ]

      when "prior_approval"
        type.assessment_details = %w[
          summary_of_work
          site_description
          additional_evidence
          neighbour_summary
          amenity
          past_applications
        ]

      when "planning_permission"
        type.assessment_details = %w[
          summary_of_work
          site_description
          additional_evidence
          consultation_summary
          neighbour_summary
          past_applications
        ]
      end

      type.save!
    end

    AssessmentDetail
      .where(category: "publicity_summary")
      .update_all(category: "neighbour_summary")
  end

  def down
    ApplicationType.find_each do |type|
      case type.name
      when "lawfulness_certificate"
        type.assessment_details = %w[
          summary_of_work
          site_description
          consultation_summary
          additional_evidence
          past_applications
        ]

      when "prior_approval"
        type.assessment_details = %w[
          summary_of_work
          site_description
          additional_evidence
          publicity_summary
          amenity
          past_applications
        ]

      when "planning_permission"
        type.assessment_details = %w[
          summary_of_work
          site_description
          additional_evidence
          consultation_summary
          publicity_summary
          past_applications
        ]
      end

      type.save!
    end

    AssessmentDetail
      .where(category: "neighbour_summary")
      .update_all(category: "publicity_summary")
  end
end
