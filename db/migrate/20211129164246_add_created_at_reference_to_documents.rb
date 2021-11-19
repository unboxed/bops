# frozen_string_literal: true

class AddCreatedAtReferenceToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_reference(:documents, :user, foreign_key: true)
    add_reference(:documents, :api_user, foreign_key: true)
  end
end
