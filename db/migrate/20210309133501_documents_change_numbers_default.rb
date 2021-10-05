# frozen_string_literal: true

class DocumentsChangeNumbersDefault < ActiveRecord::Migration[6.0]
  def change
    change_column :documents, :numbers, :string, default: ""
  end
end
