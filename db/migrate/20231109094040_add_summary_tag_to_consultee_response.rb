# frozen_string_literal: true

class AddSummaryTagToConsulteeResponse < ActiveRecord::Migration[7.0]
  def change
    add_column :consultee_responses, :summary_tag, :string
  end
end
