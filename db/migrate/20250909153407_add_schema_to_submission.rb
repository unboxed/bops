# frozen_string_literal: true

class AddSchemaToSubmission < ActiveRecord::Migration[7.2]
  class Submission < ActiveRecord::Base; end

  def change
    add_column :submissions, :schema, :string

    up_only do
      Submission.where(schema: [nil, ""]).find_each do |submission|
        submission.update(schema: submission.request_body.dig("metadata", "source").present? ? "odp" : "planning-portal")
      end
    end
  end
end
