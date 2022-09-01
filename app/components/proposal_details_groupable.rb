# frozen_string_literal: true

module ProposalDetailsGroupable
  extend ActiveSupport::Concern

  def initialize(group:)
    @group = group
  end

  private

  attr_reader :group

  delegate :portal_name, :proposal_details, to: :group

  def auto_answered?
    proposal_details.all? do |proposal_detail|
      proposal_detail.metadata&.auto_answered.present?
    end
  end

  def id
    name.downcase.gsub(/[^0-9a-z]/i, "")
  end

  def title
    name.downcase.underscore.humanize
  end

  def name
    case portal_name
    when "_root"
      t("proposal_details.main")
    when nil
      t("proposal_details.other")
    else
      portal_name
    end
  end
end
