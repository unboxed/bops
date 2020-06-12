class CreateDrawings < ActiveRecord::Migration[6.0]
  def change
    create_table :drawings do |t|
      t.string :name, default: false, null: false
      t.references :planning_application

      t.timestamps
    end
  end
end
