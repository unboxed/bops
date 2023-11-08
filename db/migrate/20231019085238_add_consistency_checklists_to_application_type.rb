# frozen_string_literal: true

class AddConsistencyChecklistsToApplicationType < ActiveRecord::Migration[7.0]
  def change
    add_column :application_types, :consistency_checklist, :string, array: true

    ApplicationType.all.find_each do |type|
      checklist = case type.name.to_sym
      when :prior_approval
        %w[
          description_matches_documents
          documents_consistent
          proposal_details_match_documents
          proposal_measurements_match_documents
          site_map_correct
        ]
      else
        %w[
          description_matches_documents
          documents_consistent
          proposal_details_match_documents
          site_map_correct
        ]
      end
      type.update(consistency_checklist: checklist)
    end
  end
end
