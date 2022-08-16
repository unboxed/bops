# frozen_string_literal: true

module ProposalDetailsPresenter
  extend ActiveSupport::Concern

  included do
    attr_accessor :hide_auto_answered_proposal_details

    def fee_related_proposal_details
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name&.match(/(_|\b)fee(_|\b)/i)
      end
    end

    def filtered_proposal_detail_groups_with_numbers
      if hide_auto_answered_proposal_details
        applicant_answered_proposal_detail_groups_with_numbers
      else
        proposal_detail_groups_with_numbers
      end
    end

    private

    def applicant_answered_proposal_detail_groups_with_numbers
      proposal_detail_groups_with_numbers.select do |group|
        group.proposal_details = group.proposal_details.select do |proposal_detail|
          proposal_detail.metadata&.auto_answered.blank?
        end

        group.proposal_details.any?
      end
    end

    def proposal_detail_groups_with_numbers
      proposal_detail_groups.tap do |groups|
        groups.map(&:proposal_details).flatten.each_with_index do |proposal_detail, index|
          proposal_detail.number = index + 1
        end
      end
    end

    def proposal_detail_groups
      proposal_detail_portal_names.map do |portal_name|
        OpenStruct.new(
          portal_name: portal_name,
          proposal_details: proposal_details_for_portal_name(portal_name)
        )
      end
    end

    def proposal_details_for_portal_name(portal_name)
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name == portal_name
      end
    end

    def proposal_detail_portal_names
      proposal_details.map do |proposal_detail|
        proposal_detail.metadata&.portal_name
      end.uniq
    end
  end
end
