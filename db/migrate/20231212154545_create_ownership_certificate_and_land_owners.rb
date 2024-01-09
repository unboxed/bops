# frozen_string_literal: true

class CreateOwnershipCertificateAndLandOwners < ActiveRecord::Migration[7.0]
  def change
    create_table :ownership_certificates do |t|
      t.references :planning_application, null: false
      t.string :certificate_type
      t.timestamps
    end

    create_table :land_owners do |t|
      t.references :ownership_certificate, null: false
      t.string :name
      t.string :address_1
      t.string :address_2
      t.string :town
      t.string :county
      t.string :country
      t.string :postcode
      t.boolean :notice_given, default: true, null: false
      t.datetime :notice_given_at
      t.timestamps
    end
  end
end
