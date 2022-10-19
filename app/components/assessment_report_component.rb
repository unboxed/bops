# frozen_string_literal: true

class AssessmentReportComponent < ViewComponent::Base
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  private

  attr_reader :planning_application

  delegate(
    :constraints,
    :past_applications,
    :summary_of_work,
    :site_description,
    :consultation_summary,
    :consultees,
    :policy_classes,
    to: :planning_application
  )

  def documents
    planning_application.documents.referenced_in_decision_notice
  end
end
