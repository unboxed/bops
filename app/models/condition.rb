# frozen_string_literal: true

class Condition < ApplicationRecord
  belongs_to :condition_set
  has_many :validation_requests, class_name: "ValidationRequest", dependent: :destroy

  validates :text, :reason, presence: true
  validates :title, presence: true, if: :pre_commencement?

  after_create :create_validation_request, if: :pre_commencement?
  before_update :maybe_create_validation_request, if: :pre_commencement?

  def checked?
    persisted? || errors.present?
  end

  def sort_key
    [title_key, timestamp_key, Float::INFINITY].compact.first
  end

  def review_title
    title.presence || "Other"
  end

  def current_validation_request
    validation_requests.order(:created_at).last
  end

  private

  def titles
    @titles ||= I18n.t(:conditions_list).values.pluck(:title)
  end

  def title_key
    titles.index(title)
  end

  def timestamp_key
    created_at&.to_i
  end

  def maybe_create_validation_request
    return unless current_validation_request.closed?
    return unless title_changed? && text_changed? && reason_changed?

    create_validation_request
  end

  def create_validation_request
    validation_requests.create(type: "PreCommencementConditionValidationRequest", planning_application: condition_set.planning_application, post_validation: true, user: Current.user)
  end

  def pre_commencement?
    condition_set.pre_commencement?
  end
end
