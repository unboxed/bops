# frozen_string_literal: true

class ConsulteeConstraint < ApplicationRecord
  belongs_to :consultee, class_name: "Contact"
  belongs_to :constraint

  validates :constraint_id, uniqueness: {scope: :consultee_id}
  validate :contact_category_is_consultee

  def contact_category_is_consultee
    return if consultee&.consultee?

    errors.add(:consultee, :invalid)
  end
end
