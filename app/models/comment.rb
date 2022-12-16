# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :commentable, polymorphic: true

  validates :text, presence: true

  before_save :set_user

  delegate :name, to: :user, prefix: true, allow_nil: true

  def first?
    previous.blank? || previous.deleted?
  end

  def deleted?
    deleted_at.present?
  end

  private

  def previous
    @previous ||= commentable.comments.where(created_at: ...created_at).last
  end

  def set_user
    self.user = Current.user
  end
end
