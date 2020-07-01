# frozen_string_literal: true

class Drawing < ApplicationRecord
  belongs_to :planning_application

  has_one_attached :plan

  enum archive_reason: { scale: 0, design: 1,
                         dimensions: 2, other: 3 }

  def is_archived?
     archived_at == nil ? false : true
   end

  def archive(archive_reason)
    self.update(archive_reason: archive_reason, archived_at: Time.zone.now)
  end
end
