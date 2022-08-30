# frozen_string_literal: true

module ProposalDetailsPresenter
  extend ActiveSupport::Concern

  included do
    def fee_related_proposal_details
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name&.match(/(_|\b)fee(_|\b)/i)
      end
    end

    def formatted_proposal_detail_groups
      number_proposal_details
      set_proposal_details_auto_answered
      proposal_detail_groups
    end

    private

    def set_proposal_details_auto_answered
      proposal_detail_groups.each do |group|
        group.proposal_details.each do |proposal_detail|
          proposal_detail.auto_answered = proposal_detail.metadata&.auto_answered.present?
        end

        group.auto_answered = group.proposal_details.all?(&:auto_answered)
      end
    end

    def number_proposal_details
      proposal_detail_groups.map(&:proposal_details).flatten.each_with_index do |proposal_detail, index|
        proposal_detail.number = index + 1
      end
    end

    def proposal_detail_groups
      @proposal_detail_groups ||= proposal_detail_portal_names.map do |portal_name|
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
