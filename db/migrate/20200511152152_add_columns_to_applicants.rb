# frozen_string_literal: true

class AddColumnsToApplicants < ActiveRecord::Migration[6.0]
  def change
    add_column :applicants, :residence_status, :boolean
    add_column :applicants, :first_name, :string
    add_column :applicants, :last_name, :string
    add_column :applicants, :company_name, :string
    add_column :applicants, :company_number, :string
    add_column :applicants, :address_1, :string
    add_column :applicants, :address_2, :string
    add_column :applicants, :address_3, :string
    add_column :applicants, :town, :string
    add_column :applicants, :postcode, :string
    add_column :applicants, :country, :string
    add_column :applicants, :phone_2, :string
  end
end
