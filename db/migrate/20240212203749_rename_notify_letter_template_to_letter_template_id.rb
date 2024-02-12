# frozen_string_literal: true

class RenameNotifyLetterTemplateToLetterTemplateId < ActiveRecord::Migration[7.1]
  def up
    rename_column :local_authorities, :notify_letter_template, :letter_template_id
    change_column :local_authorities, :letter_template_id, :uuid, using: "letter_template_id::uuid"
  end

  def down
    rename_column :local_authorities, :letter_template_id, :notify_letter_template
    change_column :local_authorities, :notify_letter_template, :string
  end
end
