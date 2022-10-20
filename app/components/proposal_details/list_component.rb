# frozen_string_literal: true

module ProposalDetails
  class ListComponent < ViewComponent::Base
    def initialize(proposal_details:)
      @proposal_details = proposal_details
      set_proposal_detail_numbers
    end

    private

    attr_reader :proposal_details

    def groups
      @groups ||= portal_names.map do |portal_name|
        OpenStruct.new(
          portal_name: portal_name,
          proposal_details: proposal_details_for_portal_name(portal_name)
        )
      end
    end

    def set_proposal_detail_numbers
      groups.map(&:proposal_details).flatten.each_with_index do |proposal_detail, index|
        proposal_detail.number = index + 1
      end
    end

    def proposal_details_for_portal_name(portal_name)
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name == portal_name
      end
    end

    def portal_names
      proposal_details.map do |proposal_detail|
        proposal_detail.metadata&.portal_name
      end.uniq
    end
  end
end
