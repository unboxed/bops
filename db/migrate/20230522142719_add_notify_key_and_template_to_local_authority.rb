# frozen_string_literal: true

class AddNotifyKeyAndTemplateToLocalAuthority < ActiveRecord::Migration[7.0]
  def change
    change_table :local_authorities, bulk: true do |t|
      t.column :notify_api_key, :string
      t.column :notify_letter_template, :string
    end
  end
end
