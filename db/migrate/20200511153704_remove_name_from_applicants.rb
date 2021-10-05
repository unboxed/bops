# frozen_string_literal: true

class RemoveNameFromApplicants < ActiveRecord::Migration[6.0]
  def change
    remove_column :applicants, :name, :string
  end
end
