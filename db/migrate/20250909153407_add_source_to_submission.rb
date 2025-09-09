# frozen_string_literal: true

class AddSourceToSubmission < ActiveRecord::Migration[7.2]
  class Submission < ActiveRecord::Base; end

  def change
    add_column :submissions, :source, :string

    up_only do
      Submission.where(source: [nil, ""]).find_each do |submission|
        submission.update(source: submission.request_body.dig("metadata", "source") || "Planning Portal")
      end
    end
  end
end
