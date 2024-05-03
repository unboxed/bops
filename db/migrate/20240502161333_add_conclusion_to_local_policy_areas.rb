# frozen_string_literal: true

class AddConclusionToLocalPolicyAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :local_policy_areas, :conclusion, :text
  end
end
