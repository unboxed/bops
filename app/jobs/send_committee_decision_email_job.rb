# frozen_string_literal: true

class SendCommitteeDecisionEmailJob < ApplicationJob
  queue_as :low_priority

  def perform(user)
    PlanningApplicationMailer.committee_decision_mail(
      planning_application,
      self
    ).deliver_now
  end
end
