# frozen_string_literal: true

class AddAgentToApplicants < ActiveRecord::Migration[6.0]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_reference :applicants, :agent, null: false, foreign_key: true
    # rubocop:enable Rails/NotNullColumn
  end
end
