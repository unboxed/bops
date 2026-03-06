# frozen_string_literal: true

module Tasks
  class MakeDraftRecommendationForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    attribute :recommend, :boolean
    attribute :reasons, :list, default: []
    attribute :decision, :string
    attribute :public_comment, :string
    attribute :assessor_comment, :string
    attribute :other_reason, :string

    after_initialize do
      recommendation = planning_application.existing_or_new_recommendation
      committee_decision = planning_application.committee_decision

      self.decision = planning_application.decision
      self.public_comment = planning_application.public_comment
      self.assessor_comment = recommendation.assessor_comment
      self.recommend = committee_decision&.recommend
      self.reasons = Array(committee_decision&.reasons).select { |r| CommitteeDecision::REASONS.include?(r) }
      self.other_reason = Array(committee_decision&.reasons).reject { |r| CommitteeDecision::REASONS.include?(r) }.first
    end

    with_options on: :save_and_complete do
      validates :recommend, inclusion: {in: [true, false], message: "Select whether the application needs to be decided by committee."}
      validates :reasons, presence: {message: "Explain why the application needs to be decided by committee"}, if: :committee_needed?
      validates :decision, presence: true
      validates :public_comment, presence: true
    end

    private

    def committee_needed?
      recommend == true
    end

    def updated_reasons
      (Array(reasons) + [other_reason]).compact_blank
    end

    def save_recommendation(status:)
      recommendation = planning_application.pending_or_new_recommendation
      recommendation.assessor = Current.user
      recommendation.assessor_comment = assessor_comment
      recommendation.status = status
      recommendation.save!
    end

    def save_committee_decision
      if planning_application.committee_decision.present?
        planning_application.committee_decision.tap do |cd|
          cd.update!(reasons: updated_reasons, recommend: recommend)
          cd.current_review.updated!
        end
      else
        CommitteeDecision.new(
          planning_application: planning_application,
          recommend: recommend,
          reasons: updated_reasons
        ).save!
      end
    end

    def save_draft
      super do
        planning_application.update!(decision: decision, public_comment: public_comment)
        save_recommendation(status: :assessment_in_progress)
        save_committee_decision unless recommend.nil?
      end
    end

    def save_and_complete
      super do
        planning_application.update!(decision: decision, public_comment: public_comment)
        save_recommendation(status: :assessment_complete)
        save_committee_decision unless recommend.nil?
        planning_application.assess!
      end
    end

    def form_params(params)
      params.fetch(param_key, {}).permit(
        :recommend,
        :decision,
        :public_comment,
        :assessor_comment,
        :other_reason,
        reasons: []
      )
    end
  end
end
