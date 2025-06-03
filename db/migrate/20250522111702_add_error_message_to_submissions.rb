# frozen_string_literal: true

class AddErrorMessageToSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :submissions, :error_message, :string
  end
end
