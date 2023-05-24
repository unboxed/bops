class CreateConsultationTable < ActiveRecord::Migration[7.0]
  def change
    create_table :consultations do |t|
      t.datetime :start_date
      t.references :planning_application
      t.timestamps
    end

    create_table :neighbours do |t|
      t.string :name
      t.string :address
      t.references :consultation
      t.timestamps
    end

    add_reference :consultees, :consultation
  end
end
