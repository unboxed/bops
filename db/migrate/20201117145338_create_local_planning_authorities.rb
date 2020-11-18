class CreateLocalPlanningAuthorities < ActiveRecord::Migration[6.0]
  def change
    create_table :local_planning_authorities do |t|
      t.string :name
      t.string :subdomain

      t.timestamps
    end
  end
end
