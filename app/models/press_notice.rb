# frozen_string_literal: true

class PressNotice < ApplicationRecord
  include Auditable

  belongs_to :planning_application

  with_options presence: true do
    validates :reasons, if: :required?
  end

  validates :required, inclusion: { in: [true, false] }

  after_save :audit_press_notice!

  delegate :audits, to: :planning_application

  class << self
    def reasons_list
      I18n.t("press_notice_reasons")
    end

    def reason_keys
      reasons_list.keys.flatten
    end
  end

  private

  def audit_press_notice!
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
end
