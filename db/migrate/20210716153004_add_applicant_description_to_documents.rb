# frozen_string_literal: true

class AddApplicantDescriptionToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :applicant_description, :text
  end
end
