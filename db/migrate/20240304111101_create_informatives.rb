class CreateInformatives < ActiveRecord::Migration[7.1]
  def change
    create_table :informatives do |t|
      t.string :title
      t.text :text
      t.references :planning_application
      t.timestamps
    end
  end
end
