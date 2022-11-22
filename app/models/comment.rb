# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true

  validates :text, presence: true

  before_save :set_user_or_current_user

  delegate :name, to: :user, prefix: true, allow_nil: true

  def edited?
    created_at != updated_at
  end

  private

  def set_user_or_current_user
    self.user = user || self.user = Current.user
  end
end
