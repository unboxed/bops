# frozen_string_literal: true

class AddPublicToHeadsOfTerms < ActiveRecord::Migration[7.1]
  def change
    add_column :heads_of_terms, :public, :boolean, default: false, null: false

    HeadsOfTerm.find_each do |term|
      term.update(public: true)
    end
  end
end
