class AddCorrectionToDecisions < ActiveRecord::Migration[6.0]
  def change
    add_column :decisions, :correction, :text
  end
end
