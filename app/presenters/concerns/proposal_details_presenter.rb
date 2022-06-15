# frozen_string_literal: true

module ProposalDetailsPresenter
  extend ActiveSupport::Concern

  included do
    def fee_related_proposal_details
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name&.match(/(_|\b)fee(_|\b)/i)
      end
    end

    def grouped_proposal_details_with_start_numbers
      grouped_proposal_details.each_with_index.map do |group, index|
        question_count = grouped_proposal_details.first(index).map(&:last).flatten.count
        group.dup.push(question_count + 1)
      end
    end

    def grouped_proposal_details
      @grouped_proposal_details ||= proposal_detail_groups.map do |group|
        [group, proposal_details_for_group(group)]
      end
    end

    private

    def proposal_details_for_group(group)
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name == group
      end
    end

    def proposal_detail_groups
      proposal_details.map do |proposal_detail|
        proposal_detail.metadata&.portal_name
      end.uniq
    end
  end
end
