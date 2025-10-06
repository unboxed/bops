# frozen_string_literal: true

class NeighbourLetter < ApplicationRecord
  belongs_to :neighbour
  belongs_to :batch, optional: true, class_name: :NeighbourLetterBatch

  validates :resend_reason, absence: true, unless: :allowed_resend_reason?
  validates :resend_reason, presence: true, if: :needs_resend_reason?

  STATUSES = {
    technical_failure: "technical failure",
    permanent_failure: "permanent failure",
    rejected: "rejected",
    submitted: "submitted",
    accepted: "printing",
    received: "posted",
    cancelled: "cancelled",
    error: "error"
  }.freeze

  FAILURE_STATUSES = %i[technical_failure permanent_failure rejected].freeze

  scope :failed, -> { where(status: FAILURE_STATUSES) }
  scope :sent, -> { where.not(status: FAILURE_STATUSES) }

  def update_status
    return false if notify_id.blank?
    return false if local_authority.notify_error_status == "bad_api_key"

    begin
      response = Notifications::Client.new(notify_api_key).get_notification(notify_id)
    rescue Notifications::Client::AuthError => e
      local_authority.update!(notify_error_status: "bad_api_key") if /Invalid token/.match?(e.message)

      return
    rescue Notifications::Client::RequestError
      return
    end

    self.status = response.status.parameterize(separator: "_")
    self.status_updated_at = response.sent_at || response.created_at
    save # rubocop:disable Rails/SaveBang
  end

  private

  def local_authority
    neighbour.consultation.planning_application.local_authority
  end

  def notify_api_key
    local_authority.notify_api_key
  end

  def resend?
    neighbour.last_letter_sent_at.present?
  end

  def needs_resend_reason?
    resend? && !neighbour.sent_comment? && planning_application_in_assessment?
  end

  def allowed_resend_reason?
    resend? || neighbour.sent_comment?
  end

  def planning_application_in_assessment?
    neighbour.consultation.planning_application.in_assessment?
  end
end
