# frozen_string_literal: true

module Tasks
  class EvidenceOfImmunityForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    after_initialize do
      @immunity_detail = planning_application.immunity_detail
    end

    attr_reader :immunity_detail

    delegate :evidence_groups, to: :immunity_detail

    def previous_reviewer_comments
      @previous_reviewer_comments ||= immunity_detail.reviews.evidence.not_accepted.select { |r| r.comment.present? }
    end

    private

    def save_draft
      super do
        update_immunity_detail!(:in_progress)
      end
    end

    def save_and_complete
      super do
        update_immunity_detail!(:complete)
      end
    end

    def update_immunity_detail!(review_status)
      current_review = immunity_detail.current_evidence_review
      review_id = current_review&.id unless review_status == :complete && current_review && !current_review.in_progress?

      immunity_detail.update!(
        **immunity_detail_params.merge(
          reviews_attributes: [{
            status: review_status,
            specific_attributes: {"review_type" => "evidence"},
            id: review_id
          }]
        )
      )
    end

    def immunity_detail_params
      @params.require(:immunity_detail).permit(
        evidence_groups_attributes: [
          :id,
          :start_date,
          :end_date,
          :missing_evidence,
          :missing_evidence_entry,
          {comments_attributes: [:text]}
        ]
      )
    end
  end
end
