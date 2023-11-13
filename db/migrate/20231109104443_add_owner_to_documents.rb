# frozen_string_literal: true

class AddOwnerToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_reference :documents, :owner, index: true, polymorphic: true
  end
end
