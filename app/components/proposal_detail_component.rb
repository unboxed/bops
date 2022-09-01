# frozen_string_literal: true

class ProposalDetailComponent < ViewComponent::Base
  include ProposalDetailsHelper

  def initialize(proposal_detail:)
    @proposal_detail = proposal_detail
  end

  private

  attr_reader :proposal_detail

  delegate :number, :metadata, to: :proposal_detail

  def auto_answered?
    metadata&.auto_answered.present?
  end
end
