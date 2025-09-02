# frozen_string_literal: true

class AddEmailTemplateIdToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :email_template_id, :uuid
  end
end
