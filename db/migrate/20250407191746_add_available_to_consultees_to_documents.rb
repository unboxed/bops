# frozen_string_literal: true

# rubocop:disable Rails/ThreeStateBooleanColumn
class AddAvailableToConsulteesToDocuments < ActiveRecord::Migration[7.2]
  class Document < ActiveRecord::Base; end

  def change
    add_column :documents, :available_to_consultees, :boolean, default: false
    add_check_constraint :documents, "available_to_consultees IS NOT NULL", validate: false

    up_only do
      Document.update_all(available_to_consultees: false)
    end
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
