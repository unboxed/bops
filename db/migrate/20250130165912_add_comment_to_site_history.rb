# frozen_string_literal: true

class AddCommentToSiteHistory < ActiveRecord::Migration[7.2]
  def change
    add_column :site_histories, :comment, :text
  end
end
