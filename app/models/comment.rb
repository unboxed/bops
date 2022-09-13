# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :policy

  validates :text, presence: true

  before_save :set_user

  delegate :name, to: :user, prefix: true, allow_nil: true

  def edited?
    created_at != updated_at
  end

  private

  def set_user
    self.user = Current.user
  end
end
