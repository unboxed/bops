class AddSignatoryToLocalAuthority < ActiveRecord::Migration[6.0]
  def change
    add_column :local_authorities, :signatory_name, :string
    add_column :local_authorities, :signatory_job_title, :string
    add_column :local_authorities, :enquiries_paragraph, :text
    add_column :local_authorities, :email_address, :string
  end
end
