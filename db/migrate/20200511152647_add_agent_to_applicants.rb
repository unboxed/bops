class AddAgentToApplicants < ActiveRecord::Migration[6.0]
  def change
    add_reference :applicants, :agent, null: false, foreign_key: true
  end
end
