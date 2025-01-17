# frozen_string_literal: true

class AddSiteMapCorrectCommentToConsistencyChecklists < ActiveRecord::Migration[7.2]
  def change
    add_column :consistency_checklists, :site_map_correct_comment, :text
  end
end
