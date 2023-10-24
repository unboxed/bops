# frozen_string_literal: true

class PressNotice < ApplicationRecord
  include Auditable

  belongs_to :planning_application
  has_many :documents, dependent: :destroy

  with_options presence: true do
    validates :reasons, if: :required?
  end

  validates :required, inclusion: {in: [true, false]}

  after_update :update_consultation_end_date!
  after_save :audit_press_notice!

  delegate :audits, to: :planning_application
  delegate :consultation, to: :planning_application
  delegate :press_notice_email, to: "planning_application.local_authority", allow_nil: true

  scope :required, -> { where(required: true) }

  accepts_nested_attributes_for :documents

  class << self
    def reasons_list
      I18n.t("press_notice_reasons")
    end

    def reason_keys
      reasons_list.keys.flatten
    end
  end

  def send_press_notice_mail
    return unless required
    return if press_notice_email.blank?

    transaction do
      PlanningApplicationMailer.press_notice_mail(self).deliver_now
      update!(requested_at: Time.current)

      audit!(
        activity_type: "press_notice_mail",
        audit_comment: "Press notice request was sent to #{press_notice_email}"
      )
    end
  end

  private

  def audit_press_notice!
    return unless saved_change_to_required? || saved_change_to_reasons?

    comment = if reasons.present?
      "Press notice has been marked as required with the following reasons: #{joined_reasons}"
    else
      "Press notice has been marked as not required"
    end

    audit!(
      activity_type: "press_notice",
      audit_comment: comment
    )
  end

  def joined_reasons
    reasons.values.join(", ")
  end

  def update_consultation_end_date!
    return unless consultation
    return unless saved_changes.include? "published_at"

    new_end_date = published_at + 21.days

    return unless consultation.end_date.nil? || new_end_date > consultation.end_date

    consultation.update!(end_date: new_end_date)
  end
end
