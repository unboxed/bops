# frozen_string_literal: true

module ProposalDetailsPresenter
  extend ActiveSupport::Concern

  included do
    def fee_related_proposal_details
      proposal_details.select do |proposal_detail|
        proposal_detail.portal_name&.match(/(_|\b)fee(_|\b)/i)
      end
    end
  end
end
