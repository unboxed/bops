# frozen_string_literal: true

class EvidenceGroupPresenter
  include BopsCore::Presentable

  presents :evidence_group

  def initialize(template, evidence_group)
    @template = template
    @evidence_group = evidence_group
  end

  def name
    I18n.t(:"#{evidence_group.tag}", scope: :document_tags).pluralize
  end

  def date_range
    if start_date.present?
      start_date.to_fs(:day_month_year_slashes) +
        (end_date.present? ? " to #{end_date.to_fs(:day_month_year_slashes)}" : "")
    else
      "dates unknown"
    end
  end

  private

  attr_reader :evidence_group
end
