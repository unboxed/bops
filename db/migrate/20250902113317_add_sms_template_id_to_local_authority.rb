# frozen_string_literal: true

class AddSmsTemplateIdToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :sms_template_id, :uuid
  end
end
