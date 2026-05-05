# frozen_string_literal: true

class Task < ApplicationRecord
  include AASM

  STATUSES = %w[not_started in_progress completed cannot_start_yet action_required]
  enum :status, STATUSES.index_by(&:to_sym)

  belongs_to :parent, polymorphic: true
  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true

  validates :slug, :name, presence: true, strict: true
  validates :status, inclusion: STATUSES

  aasm column: :status, whiny_persistence: true do
    state :not_started, initial: true
    state :in_progress, :completed, :cannot_start_yet, :action_required

    event :start do
      transitions from: :completed, to: :completed
      transitions from: %i[not_started in_progress], to: :in_progress
    end

    event :complete do
      transitions from: %i[not_started in_progress action_required completed], to: :completed
    end

    event :cannot_start_yet do
      transitions to: :cannot_start_yet
    end

    event :action_required do
      transitions to: :action_required
    end
  end

  after_initialize do
    self.slug ||= name.to_s.parameterize
  end

  def full_slug
    @full_slug ||= parent.is_a?(Task) ? "#{parent.full_slug}/#{slug}" : slug
  end

  def case_record
    @case_record ||= parent&.case_record || self
  end

  def to_param
    full_slug
  end

  def top_level?
    parent_type == "CaseRecord"
  end

  def top_level_ancestor
    top_level? ? self : parent.top_level_ancestor
  end

  def in_section?(section_name)
    top_level_ancestor.section == section_name
  end

  def validation_task?
    in_section?("Validation")
  end

  def task_for(slug)
    Task.find_by!(slug: slug)
  end

  def title
    I18n.t("bops_enforcements.tasks.title.#{slug}", default: name)
  end

  def first_child
    return self if section.blank?

    tasks.first&.first_child
  end

  def url(**args)
    @url ||= case_record.url_helpers.task_path(case_record.caseable, self, **args)
  end

  private

  def raise_not_saved(transition)
    raise ActiveRecord::RecordNotSaved, "Unable to #{transition} the task #{name.inspect}"
  end
end
