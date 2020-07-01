# frozen_string_literal: true

class Drawing < ApplicationRecord
  belongs_to :planning_application

  has_one_attached :plan

  enum archive_reason: { scale: 0, design: 1,
                         dimensions: 2, other: 3 }

  def archived?
     archived_at.present?
   end

  def archive(archive_reason)
    update(archive_reason: archive_reason,
           archived_at: Time.current) unless archived?
  end
end
