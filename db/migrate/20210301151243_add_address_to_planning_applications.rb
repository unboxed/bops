class AddAddressToPlanningApplications < ActiveRecord::Migration[6.0]
  change_table(:planning_applications) do |t|
    t.string "address_1"
    t.string "address_2"
    t.string "town"
    t.string "county"
    t.string "postcode"
    t.string "uprn"
  end
end
