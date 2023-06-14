# frozen_string_literal: true

class Consultation < ApplicationRecord
  belongs_to :planning_application
  has_many :consultees, dependent: :destroy
  has_many :neighbours, dependent: :destroy
  has_many :neighbour_letters, through: :neighbours

  accepts_nested_attributes_for :consultees, :neighbours

  enum status: {
    not_started: "not_started",
    in_progress: "in_progress",
    complete: "complete"
  }

  def end_date_from_now
    # Letters are printed at 5:30pm and dispatched the next working day (Monday to Friday)
    # Second class letters are delivered 2 days after they’re dispatched.
    # Royal Mail delivers from Monday to Saturday, excluding bank holidays.
    1.business_day.from_now + 21.days
  end

  def neighbour_letter_text
    I18n.t("neighbour_letter_template")
  end
end
