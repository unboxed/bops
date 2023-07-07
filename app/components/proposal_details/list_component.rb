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
      @groups ||= section_names.map do |section_name|
        Struct.new(:section_name, :proposal_details).new(
          section_name,
          proposal_details_for_section_name(section_name)
        )
      end
    end

    def set_proposal_detail_numbers
      groups.map(&:proposal_details).flatten.each_with_index do |proposal_detail, index|
        proposal_detail.index = index + 1
      end
    end

    def proposal_details_for_section_name(section_name)
      proposal_details.select do |proposal_detail|
        proposal_detail.send(portal_or_section_name) == section_name
      end
    end

    def section_names
      proposal_details.map(&portal_or_section_name.to_s.to_sym).uniq
    end

    def portal_or_section_name
      # To handle older planning applications which came through with only portal_name
      # instead of the new section_name
      proposal_details.any?(&:section_name) ? "section_name" : "portal_name"
    end
  end
end
