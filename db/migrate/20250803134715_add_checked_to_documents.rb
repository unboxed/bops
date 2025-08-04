# frozen_string_literal: true

class AddCheckedToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :checked, :boolean, default: false, null: false

    up_only do
      Document.where.not(validated: nil).update_all(checked: true)
    end
  end
end
