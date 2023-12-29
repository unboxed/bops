# frozen_string_literal: true

class MigratePlanningApplicationProposalDetailsJsonStringToJson < ActiveRecord::Migration[7.0]
  def change
    up_only do
      PlanningApplication.find_each do |pa|
        proposal_details = pa.read_attribute(:proposal_details)
        next if proposal_details.blank?

        if proposal_details.is_a?(String)
          begin
            parsed_json = JSON.parse(proposal_details)
            pa.update_column(:proposal_details, parsed_json)
          rescue JSON::ParserError => e
            puts "There was an issue parsing the JSON in planning application #{pa.id}: #{e.message}"
          end
        end
      end
    end
  end
end
