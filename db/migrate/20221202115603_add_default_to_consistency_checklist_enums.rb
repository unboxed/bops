# frozen_string_literal: true

class AddDefaultToConsistencyChecklistEnums < ActiveRecord::Migration[6.1]
  def change
    change_table :consistency_checklists, bulk: true do |t|
      t.change_default(:description_matches_documents, from: nil, to: 0)
      t.change_default(:documents_consistent, from: nil, to: 0)
      t.change_default(:proposal_details_match_documents, from: nil, to: 0)
    end
  end
end
