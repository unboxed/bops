class AddConsulteeRequiredToConstraint < ActiveRecord::Migration[7.1]
  def change
    add_column :constraints, :consultee_required, :boolean
  end
end
